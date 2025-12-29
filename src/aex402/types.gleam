//// AeX402 SDK Types
////
//// Type definitions for all account structures used in the AeX402 AMM.
//// These match the C structs defined in aex402.c.

import gleam/option.{type Option}

// ============================================================================
// Public Key Type (32 bytes)
// ============================================================================

/// A 32-byte Solana public key
pub type PublicKey =
  BitArray

/// Create an empty/zero public key
pub fn empty_pubkey() -> PublicKey {
  <<0:256>>
}

/// Check if a public key is empty/zero
pub fn is_empty_pubkey(key: PublicKey) -> Bool {
  key == <<0:256>>
}

// ============================================================================
// Candle Type (12 bytes, delta-encoded OHLCV)
// ============================================================================

/// Delta-encoded OHLCV candle data (12 bytes)
pub type Candle {
  Candle(
    /// Base price (scaled 1e6)
    open: Int,
    /// High delta (high = open + high_d)
    high_d: Int,
    /// Low delta (low = open - low_d)
    low_d: Int,
    /// Close delta signed (close = open + close_d)
    close_d: Int,
    /// Volume in 1e9 units
    volume: Int,
  )
}

/// Decoded candle with absolute values
pub type CandleDecoded {
  CandleDecoded(open: Int, high: Int, low: Int, close: Int, volume: Int)
}

/// Decode a candle from delta-encoded to absolute values
pub fn decode_candle(candle: Candle) -> CandleDecoded {
  CandleDecoded(
    open: candle.open,
    high: candle.open + candle.high_d,
    low: candle.open - candle.low_d,
    close: candle.open + candle.close_d,
    volume: candle.volume,
  )
}

// ============================================================================
// Pool Type (2-token, 1024 bytes)
// ============================================================================

/// 2-token AeX402 pool with on-chain OHLCV analytics
pub type Pool {
  Pool(
    /// 8 bytes "POOLSWAP"
    discriminator: BitArray,
    /// Pool authority
    authority: PublicKey,
    /// Token 0 mint
    mint0: PublicKey,
    /// Token 1 mint
    mint1: PublicKey,
    /// Token 0 vault
    vault0: PublicKey,
    /// Token 1 vault
    vault1: PublicKey,
    /// LP token mint
    lp_mint: PublicKey,
    /// Current amplification coefficient
    amp: Int,
    /// Initial amp for ramping
    init_amp: Int,
    /// Target amp for ramping
    target_amp: Int,
    /// Ramp start timestamp
    ramp_start: Int,
    /// Ramp stop timestamp
    ramp_stop: Int,
    /// Swap fee in basis points
    fee_bps: Int,
    /// Admin fee percentage (of swap fee)
    admin_fee_pct: Int,
    /// Token 0 balance
    bal0: Int,
    /// Token 1 balance
    bal1: Int,
    /// Total LP supply
    lp_supply: Int,
    /// Accumulated admin fee for token 0
    admin_fee0: Int,
    /// Accumulated admin fee for token 1
    admin_fee1: Int,
    /// Volume token 0
    vol0: Int,
    /// Volume token 1
    vol1: Int,
    /// Is pool paused
    paused: Bool,
    /// Pool PDA bump
    bump: Int,
    /// Vault 0 bump
    vault0_bump: Int,
    /// Vault 1 bump
    vault1_bump: Int,
    /// LP mint bump
    lp_mint_bump: Int,
    /// Pending authority for transfer
    pending_auth: PublicKey,
    /// Authority transfer initiation time
    auth_time: Int,
    /// Pending amp value
    pending_amp: Int,
    /// Amp commit time
    amp_time: Int,
    /// Total trade count
    trade_count: Int,
    /// Sum of trade amounts
    trade_sum: Int,
    /// Maximum price observed
    max_price: Int,
    /// Minimum price observed
    min_price: Int,
    /// Current hour slot
    hour_slot: Int,
    /// Current day slot
    day_slot: Int,
    /// Current hourly candle index
    hour_idx: Int,
    /// Current daily candle index
    day_idx: Int,
    /// Bloom filter (reserved)
    bloom: BitArray,
    /// 24 hourly candles
    hourly_candles: List(Candle),
    /// 7 daily candles
    daily_candles: List(Candle),
  )
}

// ============================================================================
// NPool Type (N-token, 2-8 tokens, 2048 bytes)
// ============================================================================

/// N-token pool supporting 2-8 tokens
pub type NPool {
  NPool(
    /// 8 bytes "NPOOLSWA"
    discriminator: BitArray,
    /// Pool authority
    authority: PublicKey,
    /// Number of tokens in pool (2-8)
    n_tokens: Int,
    /// Is pool paused
    paused: Bool,
    /// Pool PDA bump
    bump: Int,
    /// Amplification coefficient
    amp: Int,
    /// Swap fee in basis points
    fee_bps: Int,
    /// Admin fee percentage
    admin_fee_pct: Int,
    /// Total LP supply
    lp_supply: Int,
    /// Token mints (8 slots, unused are zero)
    mints: List(PublicKey),
    /// Token vaults (8 slots, unused are zero)
    vaults: List(PublicKey),
    /// LP token mint
    lp_mint: PublicKey,
    /// Token balances (8 slots)
    balances: List(Int),
    /// Admin fees (8 slots)
    admin_fees: List(Int),
    /// Total volume traded
    total_volume: Int,
    /// Total trade count
    trade_count: Int,
    /// Last trade slot
    last_trade_slot: Int,
  )
}

// ============================================================================
// Farm Type
// ============================================================================

/// Farming configuration for a pool
pub type Farm {
  Farm(
    /// 8 bytes "FARMSWAP"
    discriminator: BitArray,
    /// Associated pool
    pool: PublicKey,
    /// Reward token mint
    reward_mint: PublicKey,
    /// Reward rate per second
    reward_rate: Int,
    /// Farming start time
    start_time: Int,
    /// Farming end time
    end_time: Int,
    /// Total LP tokens staked
    total_staked: Int,
    /// Accumulated reward per share (scaled by 1e12)
    acc_reward: Int,
    /// Last update timestamp
    last_update: Int,
  )
}

// ============================================================================
// UserFarm Type
// ============================================================================

/// User's farming position
pub type UserFarm {
  UserFarm(
    /// 8 bytes "UFARMSWA"
    discriminator: BitArray,
    /// User's wallet
    owner: PublicKey,
    /// Associated farm
    farm: PublicKey,
    /// Staked LP amount
    staked: Int,
    /// Reward debt
    reward_debt: Int,
    /// Lock expiration timestamp
    lock_end: Int,
  )
}

// ============================================================================
// Lottery Type
// ============================================================================

/// Lottery configuration for a pool
pub type Lottery {
  Lottery(
    /// 8 bytes "LOTTERY!"
    discriminator: BitArray,
    /// Associated pool
    pool: PublicKey,
    /// Lottery authority
    authority: PublicKey,
    /// Lottery vault for LP tokens
    lottery_vault: PublicKey,
    /// Ticket price in LP tokens
    ticket_price: Int,
    /// Total tickets sold
    total_tickets: Int,
    /// Total prize pool
    prize_pool: Int,
    /// End time
    end_time: Int,
    /// Winning ticket number
    winning_ticket: Int,
    /// Has lottery been drawn
    drawn: Bool,
    /// Has prize been claimed
    claimed: Bool,
  )
}

// ============================================================================
// LotteryEntry Type
// ============================================================================

/// User's lottery entry
pub type LotteryEntry {
  LotteryEntry(
    /// 8 bytes "LOTENTRY"
    discriminator: BitArray,
    /// Entry owner
    owner: PublicKey,
    /// Associated lottery
    lottery: PublicKey,
    /// Starting ticket number
    ticket_start: Int,
    /// Number of tickets
    ticket_count: Int,
  )
}

// ============================================================================
// Registry Type
// ============================================================================

/// Pool registry for enumeration
pub type Registry {
  Registry(
    /// 8 bytes "REGISTRY"
    discriminator: BitArray,
    /// Registry authority
    authority: PublicKey,
    /// Pending authority for transfer
    pending_auth: PublicKey,
    /// Authority transfer initiation time
    auth_time: Int,
    /// Number of registered pools
    count: Int,
    /// List of registered pool addresses
    pools: List(PublicKey),
  )
}

// ============================================================================
// TWAP Result Type
// ============================================================================

/// Time-weighted average price result
pub type TwapResult {
  TwapResult(
    /// Price scaled by 1e6
    price: Int,
    /// Number of samples/candles used
    samples: Int,
    /// Confidence score (0-10000 = 0-100%)
    confidence: Int,
  )
}

/// Convert TWAP price to float representation
pub fn twap_price_as_float(result: TwapResult) -> Float {
  int.to_float(result.price) /. 1_000_000.0
}

/// Convert TWAP confidence to percentage
pub fn twap_confidence_percent(result: TwapResult) -> Float {
  int.to_float(result.confidence) /. 100.0
}

import gleam/int

// ============================================================================
// Instruction Argument Types
// ============================================================================

/// Arguments for creating a 2-token pool
pub type CreatePoolArgs {
  CreatePoolArgs(amp: Int, bump: Int)
}

/// Arguments for creating an N-token pool
pub type CreateNPoolArgs {
  CreateNPoolArgs(amp: Int, n_tokens: Int, bump: Int)
}

/// Arguments for generic swap
pub type SwapArgs {
  SwapArgs(
    /// From token index
    from: Int,
    /// To token index
    to: Int,
    /// Amount to swap in
    amount_in: Int,
    /// Minimum output amount
    min_out: Int,
    /// Transaction deadline
    deadline: Int,
  )
}

/// Arguments for simple swap (t0t1 or t1t0)
pub type SwapSimpleArgs {
  SwapSimpleArgs(
    /// Amount to swap in
    amount_in: Int,
    /// Minimum output amount
    min_out: Int,
  )
}

/// Arguments for N-token swap
pub type SwapNArgs {
  SwapNArgs(
    /// From token index
    from_idx: Int,
    /// To token index
    to_idx: Int,
    /// Amount to swap in
    amount_in: Int,
    /// Minimum output amount
    min_out: Int,
  )
}

/// Arguments for adding liquidity (2-token)
pub type AddLiqArgs {
  AddLiqArgs(
    /// Amount of token 0
    amount0: Int,
    /// Amount of token 1
    amount1: Int,
    /// Minimum LP tokens to receive
    min_lp: Int,
  )
}

/// Arguments for single-sided liquidity add
pub type AddLiq1Args {
  AddLiq1Args(
    /// Amount of input token
    amount_in: Int,
    /// Minimum LP tokens to receive
    min_lp: Int,
  )
}

/// Arguments for removing liquidity
pub type RemLiqArgs {
  RemLiqArgs(
    /// LP tokens to burn
    lp_amount: Int,
    /// Minimum token 0 to receive
    min0: Int,
    /// Minimum token 1 to receive
    min1: Int,
  )
}

/// Arguments for updating fee
pub type UpdateFeeArgs {
  UpdateFeeArgs(fee_bps: Int)
}

/// Arguments for committing amp change
pub type CommitAmpArgs {
  CommitAmpArgs(target_amp: Int)
}

/// Arguments for ramping amp
pub type RampAmpArgs {
  RampAmpArgs(target_amp: Int, duration: Int)
}

/// Arguments for creating a farm
pub type CreateFarmArgs {
  CreateFarmArgs(reward_rate: Int, start_time: Int, end_time: Int)
}

/// Arguments for staking/unstaking
pub type StakeArgs {
  StakeArgs(amount: Int)
}

/// Arguments for locking LP tokens
pub type LockLpArgs {
  LockLpArgs(amount: Int, duration: Int)
}

/// Arguments for entering lottery
pub type EnterLotteryArgs {
  EnterLotteryArgs(ticket_count: Int)
}

/// Arguments for drawing lottery
pub type DrawLotteryArgs {
  DrawLotteryArgs(random_seed: Int)
}

/// Arguments for creating lottery
pub type CreateLotteryArgs {
  CreateLotteryArgs(ticket_price: Int, end_time: Int)
}
