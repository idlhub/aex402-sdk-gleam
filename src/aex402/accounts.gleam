//// AeX402 SDK Account Parsing
////
//// Functions for parsing binary account data into typed structures.
//// Uses BitArray pattern matching for efficient binary parsing.

import gleam/bit_array
import gleam/int
import gleam/list
import gleam/result
import aex402/constants
import aex402/types.{
  type Candle, type Farm, type Lottery, type LotteryEntry, type NPool,
  type Pool, type PublicKey, type TwapResult, type UserFarm, Candle, Farm,
  Lottery, LotteryEntry, NPool, Pool, TwapResult, UserFarm,
}

// ============================================================================
// Helper Functions for Reading Binary Data (Little-Endian)
// ============================================================================

/// Read a 32-byte public key from BitArray at offset
pub fn read_pubkey(data: BitArray, offset: Int) -> Result(PublicKey, Nil) {
  bit_array.slice(data, offset, 32)
}

/// Read unsigned 8-bit integer
pub fn read_u8(data: BitArray, offset: Int) -> Result(Int, Nil) {
  case bit_array.slice(data, offset, 1) {
    Ok(<<value:8>>) -> Ok(value)
    _ -> Error(Nil)
  }
}

/// Read unsigned 16-bit integer (little-endian)
pub fn read_u16_le(data: BitArray, offset: Int) -> Result(Int, Nil) {
  case bit_array.slice(data, offset, 2) {
    Ok(<<low:8, high:8>>) -> Ok(low + high * 256)
    _ -> Error(Nil)
  }
}

/// Read signed 16-bit integer (little-endian)
pub fn read_i16_le(data: BitArray, offset: Int) -> Result(Int, Nil) {
  case bit_array.slice(data, offset, 2) {
    Ok(<<value:16-little-signed>>) -> Ok(value)
    _ -> Error(Nil)
  }
}

/// Read unsigned 32-bit integer (little-endian)
pub fn read_u32_le(data: BitArray, offset: Int) -> Result(Int, Nil) {
  case bit_array.slice(data, offset, 4) {
    Ok(<<value:32-little-unsigned>>) -> Ok(value)
    _ -> Error(Nil)
  }
}

/// Read unsigned 64-bit integer (little-endian)
pub fn read_u64_le(data: BitArray, offset: Int) -> Result(Int, Nil) {
  case bit_array.slice(data, offset, 8) {
    Ok(<<value:64-little-unsigned>>) -> Ok(value)
    _ -> Error(Nil)
  }
}

/// Read signed 64-bit integer (little-endian)
pub fn read_i64_le(data: BitArray, offset: Int) -> Result(Int, Nil) {
  case bit_array.slice(data, offset, 8) {
    Ok(<<value:64-little-signed>>) -> Ok(value)
    _ -> Error(Nil)
  }
}

/// Read a candle (12 bytes)
pub fn read_candle(data: BitArray, offset: Int) -> Result(Candle, Nil) {
  use open <- result.try(read_u32_le(data, offset))
  use high_d <- result.try(read_u16_le(data, offset + 4))
  use low_d <- result.try(read_u16_le(data, offset + 6))
  use close_d <- result.try(read_i16_le(data, offset + 8))
  use volume <- result.try(read_u16_le(data, offset + 10))
  Ok(Candle(
    open: open,
    high_d: high_d,
    low_d: low_d,
    close_d: close_d,
    volume: volume,
  ))
}

/// Read multiple candles
fn read_candles(
  data: BitArray,
  offset: Int,
  count: Int,
) -> Result(List(Candle), Nil) {
  read_candles_acc(data, offset, count, [])
}

fn read_candles_acc(
  data: BitArray,
  offset: Int,
  remaining: Int,
  acc: List(Candle),
) -> Result(List(Candle), Nil) {
  case remaining {
    0 -> Ok(list.reverse(acc))
    n -> {
      use candle <- result.try(read_candle(data, offset))
      read_candles_acc(data, offset + 12, n - 1, [candle, ..acc])
    }
  }
}

/// Read multiple pubkeys
fn read_pubkeys(
  data: BitArray,
  offset: Int,
  count: Int,
) -> Result(List(PublicKey), Nil) {
  read_pubkeys_acc(data, offset, count, [])
}

fn read_pubkeys_acc(
  data: BitArray,
  offset: Int,
  remaining: Int,
  acc: List(PublicKey),
) -> Result(List(PublicKey), Nil) {
  case remaining {
    0 -> Ok(list.reverse(acc))
    n -> {
      use pubkey <- result.try(read_pubkey(data, offset))
      read_pubkeys_acc(data, offset + 32, n - 1, [pubkey, ..acc])
    }
  }
}

/// Read multiple u64 values
fn read_u64s(
  data: BitArray,
  offset: Int,
  count: Int,
) -> Result(List(Int), Nil) {
  read_u64s_acc(data, offset, count, [])
}

fn read_u64s_acc(
  data: BitArray,
  offset: Int,
  remaining: Int,
  acc: List(Int),
) -> Result(List(Int), Nil) {
  case remaining {
    0 -> Ok(list.reverse(acc))
    n -> {
      use value <- result.try(read_u64_le(data, offset))
      read_u64s_acc(data, offset + 8, n - 1, [value, ..acc])
    }
  }
}

// ============================================================================
// Pool Parsing
// ============================================================================

/// Parse a Pool account from binary data
pub fn parse_pool(data: BitArray) -> Result(Pool, Nil) {
  // Minimum size check
  case bit_array.byte_size(data) < 900 {
    True -> Error(Nil)
    False -> {
      // Check discriminator
      use disc <- result.try(bit_array.slice(data, 0, 8))
      case disc == constants.account_disc_pool {
        False -> Error(Nil)
        True -> parse_pool_inner(data, disc)
      }
    }
  }
}

fn parse_pool_inner(data: BitArray, disc: BitArray) -> Result(Pool, Nil) {
  // Pubkeys (6 * 32 = 192 bytes starting at offset 8)
  use authority <- result.try(read_pubkey(data, 8))
  use mint0 <- result.try(read_pubkey(data, 40))
  use mint1 <- result.try(read_pubkey(data, 72))
  use vault0 <- result.try(read_pubkey(data, 104))
  use vault1 <- result.try(read_pubkey(data, 136))
  use lp_mint <- result.try(read_pubkey(data, 168))

  // Amp fields (5 * 8 = 40 bytes starting at offset 200)
  use amp <- result.try(read_u64_le(data, 200))
  use init_amp <- result.try(read_u64_le(data, 208))
  use target_amp <- result.try(read_u64_le(data, 216))
  use ramp_start <- result.try(read_i64_le(data, 224))
  use ramp_stop <- result.try(read_i64_le(data, 232))

  // Fee fields (2 * 8 = 16 bytes starting at offset 240)
  use fee_bps <- result.try(read_u64_le(data, 240))
  use admin_fee_pct <- result.try(read_u64_le(data, 248))

  // Balance fields (5 * 8 = 40 bytes starting at offset 256)
  use bal0 <- result.try(read_u64_le(data, 256))
  use bal1 <- result.try(read_u64_le(data, 264))
  use lp_supply <- result.try(read_u64_le(data, 272))
  use admin_fee0 <- result.try(read_u64_le(data, 280))
  use admin_fee1 <- result.try(read_u64_le(data, 288))

  // Volume fields (2 * 8 = 16 bytes starting at offset 296)
  use vol0 <- result.try(read_u64_le(data, 296))
  use vol1 <- result.try(read_u64_le(data, 304))

  // Flags (5 bytes + 3 padding starting at offset 312)
  use paused_byte <- result.try(read_u8(data, 312))
  use bump <- result.try(read_u8(data, 313))
  use vault0_bump <- result.try(read_u8(data, 314))
  use vault1_bump <- result.try(read_u8(data, 315))
  use lp_mint_bump <- result.try(read_u8(data, 316))
  // offset 317-319: padding

  // Pending authority (32 + 8 = 40 bytes starting at offset 320)
  use pending_auth <- result.try(read_pubkey(data, 320))
  use auth_time <- result.try(read_i64_le(data, 352))

  // Pending amp (8 + 8 = 16 bytes starting at offset 360)
  use pending_amp <- result.try(read_u64_le(data, 360))
  use amp_time <- result.try(read_i64_le(data, 368))

  // Analytics section starting at offset 376
  use trade_count <- result.try(read_u64_le(data, 376))
  use trade_sum <- result.try(read_u64_le(data, 384))
  use max_price <- result.try(read_u32_le(data, 392))
  use min_price <- result.try(read_u32_le(data, 396))
  use hour_slot <- result.try(read_u32_le(data, 400))
  use day_slot <- result.try(read_u32_le(data, 404))
  use hour_idx <- result.try(read_u8(data, 408))
  use day_idx <- result.try(read_u8(data, 409))
  // offset 410-415: padding

  // Bloom filter (128 bytes starting at offset 416)
  use bloom <- result.try(bit_array.slice(data, 416, 128))

  // Hourly candles (24 * 12 = 288 bytes starting at offset 544)
  use hourly_candles <- result.try(read_candles(data, 544, constants.ohlcv_24h))

  // Daily candles (7 * 12 = 84 bytes starting at offset 832)
  use daily_candles <- result.try(read_candles(data, 832, constants.ohlcv_7d))

  Ok(Pool(
    discriminator: disc,
    authority: authority,
    mint0: mint0,
    mint1: mint1,
    vault0: vault0,
    vault1: vault1,
    lp_mint: lp_mint,
    amp: amp,
    init_amp: init_amp,
    target_amp: target_amp,
    ramp_start: ramp_start,
    ramp_stop: ramp_stop,
    fee_bps: fee_bps,
    admin_fee_pct: admin_fee_pct,
    bal0: bal0,
    bal1: bal1,
    lp_supply: lp_supply,
    admin_fee0: admin_fee0,
    admin_fee1: admin_fee1,
    vol0: vol0,
    vol1: vol1,
    paused: paused_byte != 0,
    bump: bump,
    vault0_bump: vault0_bump,
    vault1_bump: vault1_bump,
    lp_mint_bump: lp_mint_bump,
    pending_auth: pending_auth,
    auth_time: auth_time,
    pending_amp: pending_amp,
    amp_time: amp_time,
    trade_count: trade_count,
    trade_sum: trade_sum,
    max_price: max_price,
    min_price: min_price,
    hour_slot: hour_slot,
    day_slot: day_slot,
    hour_idx: hour_idx,
    day_idx: day_idx,
    bloom: bloom,
    hourly_candles: hourly_candles,
    daily_candles: daily_candles,
  ))
}

// ============================================================================
// NPool Parsing
// ============================================================================

/// Parse an NPool account from binary data
pub fn parse_npool(data: BitArray) -> Result(NPool, Nil) {
  // Minimum size check
  case bit_array.byte_size(data) < 800 {
    True -> Error(Nil)
    False -> {
      // Check discriminator
      use disc <- result.try(bit_array.slice(data, 0, 8))
      case disc == constants.account_disc_npool {
        False -> Error(Nil)
        True -> parse_npool_inner(data, disc)
      }
    }
  }
}

fn parse_npool_inner(data: BitArray, disc: BitArray) -> Result(NPool, Nil) {
  use authority <- result.try(read_pubkey(data, 8))
  use n_tokens <- result.try(read_u8(data, 40))
  use paused_byte <- result.try(read_u8(data, 41))
  use bump <- result.try(read_u8(data, 42))
  // offset 43-47: padding

  use amp <- result.try(read_u64_le(data, 48))
  use fee_bps <- result.try(read_u64_le(data, 56))
  use admin_fee_pct <- result.try(read_u64_le(data, 64))
  use lp_supply <- result.try(read_u64_le(data, 72))

  // Mints (8 * 32 = 256 bytes starting at offset 80)
  use mints <- result.try(read_pubkeys(data, 80, constants.max_tokens))

  // Vaults (8 * 32 = 256 bytes starting at offset 336)
  use vaults <- result.try(read_pubkeys(data, 336, constants.max_tokens))

  // LP mint starting at offset 592
  use lp_mint <- result.try(read_pubkey(data, 592))

  // Balances (8 * 8 = 64 bytes starting at offset 624)
  use balances <- result.try(read_u64s(data, 624, constants.max_tokens))

  // Admin fees (8 * 8 = 64 bytes starting at offset 688)
  use admin_fees <- result.try(read_u64s(data, 688, constants.max_tokens))

  use total_volume <- result.try(read_u64_le(data, 752))
  use trade_count <- result.try(read_u64_le(data, 760))
  use last_trade_slot <- result.try(read_u64_le(data, 768))

  Ok(NPool(
    discriminator: disc,
    authority: authority,
    n_tokens: n_tokens,
    paused: paused_byte != 0,
    bump: bump,
    amp: amp,
    fee_bps: fee_bps,
    admin_fee_pct: admin_fee_pct,
    lp_supply: lp_supply,
    mints: mints,
    vaults: vaults,
    lp_mint: lp_mint,
    balances: balances,
    admin_fees: admin_fees,
    total_volume: total_volume,
    trade_count: trade_count,
    last_trade_slot: last_trade_slot,
  ))
}

// ============================================================================
// Farm Parsing
// ============================================================================

/// Parse a Farm account from binary data
pub fn parse_farm(data: BitArray) -> Result(Farm, Nil) {
  // Minimum size check
  case bit_array.byte_size(data) < 120 {
    True -> Error(Nil)
    False -> {
      // Check discriminator
      use disc <- result.try(bit_array.slice(data, 0, 8))
      case disc == constants.account_disc_farm {
        False -> Error(Nil)
        True -> {
          use pool <- result.try(read_pubkey(data, 8))
          use reward_mint <- result.try(read_pubkey(data, 40))
          use reward_rate <- result.try(read_u64_le(data, 72))
          use start_time <- result.try(read_i64_le(data, 80))
          use end_time <- result.try(read_i64_le(data, 88))
          use total_staked <- result.try(read_u64_le(data, 96))
          use acc_reward <- result.try(read_u64_le(data, 104))
          use last_update <- result.try(read_i64_le(data, 112))

          Ok(Farm(
            discriminator: disc,
            pool: pool,
            reward_mint: reward_mint,
            reward_rate: reward_rate,
            start_time: start_time,
            end_time: end_time,
            total_staked: total_staked,
            acc_reward: acc_reward,
            last_update: last_update,
          ))
        }
      }
    }
  }
}

// ============================================================================
// UserFarm Parsing
// ============================================================================

/// Parse a UserFarm account from binary data
pub fn parse_user_farm(data: BitArray) -> Result(UserFarm, Nil) {
  // Minimum size check: 8 + 32 + 32 + 8 + 8 + 8 = 96 bytes
  case bit_array.byte_size(data) < 96 {
    True -> Error(Nil)
    False -> {
      // Check discriminator
      use disc <- result.try(bit_array.slice(data, 0, 8))
      case disc == constants.account_disc_ufarm {
        False -> Error(Nil)
        True -> {
          use owner <- result.try(read_pubkey(data, 8))
          use farm <- result.try(read_pubkey(data, 40))
          use staked <- result.try(read_u64_le(data, 72))
          use reward_debt <- result.try(read_u64_le(data, 80))
          use lock_end <- result.try(read_i64_le(data, 88))

          Ok(UserFarm(
            discriminator: disc,
            owner: owner,
            farm: farm,
            staked: staked,
            reward_debt: reward_debt,
            lock_end: lock_end,
          ))
        }
      }
    }
  }
}

// ============================================================================
// Lottery Parsing
// ============================================================================

/// Parse a Lottery account from binary data
pub fn parse_lottery(data: BitArray) -> Result(Lottery, Nil) {
  // Minimum size check
  case bit_array.byte_size(data) < 152 {
    True -> Error(Nil)
    False -> {
      // Check discriminator
      use disc <- result.try(bit_array.slice(data, 0, 8))
      case disc == constants.account_disc_lottery {
        False -> Error(Nil)
        True -> {
          use pool <- result.try(read_pubkey(data, 8))
          use authority <- result.try(read_pubkey(data, 40))
          use lottery_vault <- result.try(read_pubkey(data, 72))
          use ticket_price <- result.try(read_u64_le(data, 104))
          use total_tickets <- result.try(read_u64_le(data, 112))
          use prize_pool <- result.try(read_u64_le(data, 120))
          use end_time <- result.try(read_i64_le(data, 128))
          use winning_ticket <- result.try(read_u64_le(data, 136))
          use drawn_byte <- result.try(read_u8(data, 144))
          use claimed_byte <- result.try(read_u8(data, 145))

          Ok(Lottery(
            discriminator: disc,
            pool: pool,
            authority: authority,
            lottery_vault: lottery_vault,
            ticket_price: ticket_price,
            total_tickets: total_tickets,
            prize_pool: prize_pool,
            end_time: end_time,
            winning_ticket: winning_ticket,
            drawn: drawn_byte != 0,
            claimed: claimed_byte != 0,
          ))
        }
      }
    }
  }
}

// ============================================================================
// LotteryEntry Parsing
// ============================================================================

/// Parse a LotteryEntry account from binary data
pub fn parse_lottery_entry(data: BitArray) -> Result(LotteryEntry, Nil) {
  // Minimum size check: 8 + 32 + 32 + 8 + 8 = 88 bytes
  case bit_array.byte_size(data) < 88 {
    True -> Error(Nil)
    False -> {
      // Check discriminator
      use disc <- result.try(bit_array.slice(data, 0, 8))
      case disc == constants.account_disc_lotentry {
        False -> Error(Nil)
        True -> {
          use owner <- result.try(read_pubkey(data, 8))
          use lottery <- result.try(read_pubkey(data, 40))
          use ticket_start <- result.try(read_u64_le(data, 72))
          use ticket_count <- result.try(read_u64_le(data, 80))

          Ok(LotteryEntry(
            discriminator: disc,
            owner: owner,
            lottery: lottery,
            ticket_start: ticket_start,
            ticket_count: ticket_count,
          ))
        }
      }
    }
  }
}

// ============================================================================
// TWAP Result Decoding
// ============================================================================

/// Decode TWAP result from encoded u64
pub fn decode_twap_result(encoded: Int) -> TwapResult {
  // Bits 0-31: price (scaled 1e6)
  let price = int.bitwise_and(encoded, 0xFFFFFFFF)
  // Bits 32-47: sample count
  let samples = int.bitwise_and(int.bitwise_shift_right(encoded, 32), 0xFFFF)
  // Bits 48-63: confidence (0-10000)
  let confidence =
    int.bitwise_and(int.bitwise_shift_right(encoded, 48), 0xFFFF)

  TwapResult(price: price, samples: samples, confidence: confidence)
}

// ============================================================================
// Discriminator Validation
// ============================================================================

/// Check if data has a valid pool discriminator
pub fn is_pool_account(data: BitArray) -> Bool {
  case bit_array.slice(data, 0, 8) {
    Ok(disc) -> disc == constants.account_disc_pool
    Error(_) -> False
  }
}

/// Check if data has a valid npool discriminator
pub fn is_npool_account(data: BitArray) -> Bool {
  case bit_array.slice(data, 0, 8) {
    Ok(disc) -> disc == constants.account_disc_npool
    Error(_) -> False
  }
}

/// Check if data has a valid farm discriminator
pub fn is_farm_account(data: BitArray) -> Bool {
  case bit_array.slice(data, 0, 8) {
    Ok(disc) -> disc == constants.account_disc_farm
    Error(_) -> False
  }
}

/// Check if data has a valid user farm discriminator
pub fn is_user_farm_account(data: BitArray) -> Bool {
  case bit_array.slice(data, 0, 8) {
    Ok(disc) -> disc == constants.account_disc_ufarm
    Error(_) -> False
  }
}

/// Check if data has a valid lottery discriminator
pub fn is_lottery_account(data: BitArray) -> Bool {
  case bit_array.slice(data, 0, 8) {
    Ok(disc) -> disc == constants.account_disc_lottery
    Error(_) -> False
  }
}

/// Check if data has a valid lottery entry discriminator
pub fn is_lottery_entry_account(data: BitArray) -> Bool {
  case bit_array.slice(data, 0, 8) {
    Ok(disc) -> disc == constants.account_disc_lotentry
    Error(_) -> False
  }
}
