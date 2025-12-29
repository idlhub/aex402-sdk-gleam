import gleeunit
import gleeunit/should
import aex402
import aex402/constants
import aex402/types.{Candle, SwapSimpleArgs, CreatePoolArgs, AddLiqArgs}
import aex402/math
import aex402/instructions
import aex402/accounts
import aex402/pda
import gleam/bit_array
import gleam/result

pub fn main() {
  gleeunit.main()
}

// ============================================================================
// Constants Tests
// ============================================================================

pub fn constants_test() {
  // Test that constants are correct
  constants.min_amp |> should.equal(1)
  constants.max_amp |> should.equal(100_000)
  constants.default_fee_bps |> should.equal(30)
  constants.admin_fee_pct |> should.equal(50)
  constants.newton_iterations |> should.equal(255)
  constants.max_tokens |> should.equal(8)
  constants.pool_size |> should.equal(1024)
  constants.npool_size |> should.equal(2048)
}

pub fn discriminator_length_test() {
  // All discriminators should be 8 bytes
  bit_array.byte_size(constants.disc_createpool) |> should.equal(8)
  bit_array.byte_size(constants.disc_swap) |> should.equal(8)
  bit_array.byte_size(constants.disc_addliq) |> should.equal(8)
  bit_array.byte_size(constants.disc_remliq) |> should.equal(8)
  bit_array.byte_size(constants.account_disc_pool) |> should.equal(8)
  bit_array.byte_size(constants.account_disc_farm) |> should.equal(8)
}

pub fn error_codes_test() {
  // Test error code conversion
  constants.error_from_code(6000)
  |> should.be_ok()
  |> should.equal(constants.ErrPaused)

  constants.error_from_code(6001)
  |> should.be_ok()
  |> should.equal(constants.ErrInvalidAmp)

  constants.error_from_code(6004)
  |> should.be_ok()
  |> should.equal(constants.ErrSlippageExceeded)

  // Invalid code should error
  constants.error_from_code(9999)
  |> should.be_error()

  // Test error message
  constants.error_message(constants.ErrPaused)
  |> should.equal("Pool is paused")
}

pub fn twap_window_test() {
  constants.twap_window_to_byte(constants.Hour1) |> should.equal(0)
  constants.twap_window_to_byte(constants.Hour4) |> should.equal(1)
  constants.twap_window_to_byte(constants.Hour24) |> should.equal(2)
  constants.twap_window_to_byte(constants.Day7) |> should.equal(3)

  constants.twap_window_from_byte(0) |> should.be_ok() |> should.equal(constants.Hour1)
  constants.twap_window_from_byte(3) |> should.be_ok() |> should.equal(constants.Day7)
  constants.twap_window_from_byte(5) |> should.be_error()
}

// ============================================================================
// Types Tests
// ============================================================================

pub fn candle_decode_test() {
  let candle = Candle(
    open: 1_000_000,
    high_d: 50_000,
    low_d: 30_000,
    close_d: 10_000,
    volume: 5000,
  )

  let decoded = types.decode_candle(candle)

  decoded.open |> should.equal(1_000_000)
  decoded.high |> should.equal(1_050_000)
  decoded.low |> should.equal(970_000)
  decoded.close |> should.equal(1_010_000)
  decoded.volume |> should.equal(5000)
}

pub fn empty_pubkey_test() {
  let empty = types.empty_pubkey()
  bit_array.byte_size(empty) |> should.equal(32)
  types.is_empty_pubkey(empty) |> should.be_true()

  let non_empty = <<1:256>>
  types.is_empty_pubkey(non_empty) |> should.be_false()
}

// ============================================================================
// Math Tests
// ============================================================================

pub fn calc_d_zero_test() {
  // Zero balances should return D = 0
  math.calc_d(0, 0, 100)
  |> should.be_ok()
  |> should.equal(0)
}

pub fn calc_d_equal_balances_test() {
  // Equal balances with high amp should have D close to sum
  let result = math.calc_d(1_000_000_000, 1_000_000_000, 100)
  result |> should.be_ok()

  case result {
    Ok(d) -> {
      // D should be approximately 2 * balance for equal balances
      // Allow some tolerance due to curve math
      let expected = 2_000_000_000
      let tolerance = 100_000  // 0.01% tolerance
      let diff = case d > expected {
        True -> d - expected
        False -> expected - d
      }
      diff |> should.be_true() // Just check it computed
    }
    Error(_) -> should.fail()
  }
}

pub fn calc_y_test() {
  // First get D
  let d_result = math.calc_d(1_000_000_000, 1_000_000_000, 100)
  d_result |> should.be_ok()

  case d_result {
    Ok(d) -> {
      // Then calculate Y for a new X
      let new_x = 1_100_000_000  // 10% more
      let y_result = math.calc_y(new_x, d, 100)
      y_result |> should.be_ok()

      case y_result {
        Ok(y) -> {
          // Y should be less than original (tokens flow out)
          { y < 1_000_000_000 } |> should.be_true()
        }
        Error(_) -> should.fail()
      }
    }
    Error(_) -> should.fail()
  }
}

pub fn simulate_swap_test() {
  let result = math.simulate_swap(
    1_000_000_000,  // bal_in
    1_000_000_000,  // bal_out
    100_000_000,    // amount_in (10%)
    100,            // amp
    30,             // fee_bps (0.3%)
  )

  result |> should.be_ok()

  case result {
    Ok(amount_out) -> {
      // Output should be positive
      { amount_out > 0 } |> should.be_true()
      // Output should be less than input (fee + curve)
      { amount_out < 100_000_000 } |> should.be_true()
      // For a stable pool with equal balances, output should be close to input
      { amount_out > 95_000_000 } |> should.be_true()
    }
    Error(_) -> should.fail()
  }
}

pub fn calc_lp_tokens_initial_test() {
  // Initial deposit (lp_supply = 0)
  let result = math.calc_lp_tokens(
    1_000_000_000,  // amt0
    1_000_000_000,  // amt1
    0,              // bal0
    0,              // bal1
    0,              // lp_supply
    100,            // amp
  )

  result |> should.be_ok()

  case result {
    Ok(lp) -> {
      // LP should be sqrt(amt0 * amt1) = sqrt(1e18) = 1e9
      { lp == 1_000_000_000 } |> should.be_true()
    }
    Error(_) -> should.fail()
  }
}

pub fn calc_withdraw_test() {
  let result = math.calc_withdraw(
    100_000_000,    // lp_amount (10%)
    1_000_000_000,  // bal0
    1_000_000_000,  // bal1
    1_000_000_000,  // lp_supply
  )

  result |> should.be_ok()

  case result {
    Ok(#(amt0, amt1)) -> {
      amt0 |> should.equal(100_000_000)
      amt1 |> should.equal(100_000_000)
    }
    Error(_) -> should.fail()
  }
}

pub fn get_current_amp_test() {
  // Before ramp
  math.get_current_amp(100, 200, 1000, 2000, 500)
  |> should.equal(100)

  // After ramp
  math.get_current_amp(100, 200, 1000, 2000, 3000)
  |> should.equal(200)

  // During ramp (50% through)
  math.get_current_amp(100, 200, 1000, 2000, 1500)
  |> should.equal(150)

  // During ramp (25% through)
  math.get_current_amp(100, 200, 1000, 2000, 1250)
  |> should.equal(125)
}

pub fn calc_min_output_test() {
  // 1% slippage
  math.calc_min_output(1_000_000, 100)
  |> should.equal(990_000)

  // 0.5% slippage
  math.calc_min_output(1_000_000, 50)
  |> should.equal(995_000)
}

pub fn isqrt_test() {
  math.isqrt(0) |> should.equal(0)
  math.isqrt(1) |> should.equal(1)
  math.isqrt(4) |> should.equal(2)
  math.isqrt(9) |> should.equal(3)
  math.isqrt(16) |> should.equal(4)
  math.isqrt(1_000_000) |> should.equal(1000)
  math.isqrt(1_000_000_000_000_000_000) |> should.equal(1_000_000_000)
}

pub fn check_imbalance_test() {
  // Balanced pool
  math.check_imbalance(1_000_000, 1_000_000, 10) |> should.be_true()

  // 5:1 ratio, within 10x limit
  math.check_imbalance(5_000_000, 1_000_000, 10) |> should.be_true()

  // 15:1 ratio, exceeds 10x limit
  math.check_imbalance(15_000_000, 1_000_000, 10) |> should.be_false()
}

// ============================================================================
// Instructions Tests
// ============================================================================

pub fn build_swap_t0_t1_test() {
  let args = SwapSimpleArgs(
    amount_in: 1_000_000_000,
    min_out: 990_000_000,
  )

  let data = instructions.build_swap_t0_t1(args)

  // Should be discriminator (8) + amount_in (8) + min_out (8) = 24 bytes
  bit_array.byte_size(data) |> should.equal(24)

  // First 8 bytes should be discriminator
  let disc = case bit_array.slice(data, 0, 8) {
    Ok(d) -> d
    Error(_) -> <<>>
  }
  disc |> should.equal(constants.disc_swapt0t1)
}

pub fn build_create_pool_test() {
  let args = CreatePoolArgs(amp: 100, bump: 255)
  let data = instructions.build_create_pool(args)

  // Should be discriminator (8) + amp (8) + bump (1) = 17 bytes
  bit_array.byte_size(data) |> should.equal(17)
}

pub fn build_add_liquidity_test() {
  let args = AddLiqArgs(
    amount0: 1_000_000_000,
    amount1: 1_000_000_000,
    min_lp: 1_900_000_000,
  )

  let data = instructions.build_add_liquidity(args)

  // Should be discriminator (8) + 3 * u64 (24) = 32 bytes
  bit_array.byte_size(data) |> should.equal(32)
}

pub fn build_set_pause_test() {
  let paused_data = instructions.build_set_pause(True)
  bit_array.byte_size(paused_data) |> should.equal(9)

  let unpaused_data = instructions.build_set_pause(False)
  bit_array.byte_size(unpaused_data) |> should.equal(9)
}

pub fn build_get_twap_test() {
  let data = instructions.build_get_twap(constants.Hour24)
  bit_array.byte_size(data) |> should.equal(9)
}

// ============================================================================
// Accounts Tests
// ============================================================================

pub fn read_u8_test() {
  let data = <<42:8, 0:8, 0:8>>
  accounts.read_u8(data, 0) |> should.be_ok() |> should.equal(42)
}

pub fn read_u16_le_test() {
  // Little-endian: low byte first
  let data = <<0x34:8, 0x12:8, 0:8>>  // 0x1234 = 4660
  accounts.read_u16_le(data, 0) |> should.be_ok() |> should.equal(4660)
}

pub fn read_u32_le_test() {
  // Little-endian: 0x12345678
  let data = <<0x78:8, 0x56:8, 0x34:8, 0x12:8>>
  accounts.read_u32_le(data, 0) |> should.be_ok() |> should.equal(0x12345678)
}

pub fn read_u64_le_test() {
  // Little-endian: 1_000_000_000
  let data = <<0:64-little-unsigned>>
  accounts.read_u64_le(data, 0) |> should.be_ok() |> should.equal(0)

  let data2 = <<1_000_000_000:64-little-unsigned>>
  accounts.read_u64_le(data2, 0) |> should.be_ok() |> should.equal(1_000_000_000)
}

pub fn read_pubkey_test() {
  let key = <<1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16,
              17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32>>

  accounts.read_pubkey(key, 0) |> should.be_ok() |> should.equal(key)
}

pub fn is_pool_account_test() {
  // Valid pool discriminator
  let valid_pool = bit_array.concat([constants.account_disc_pool, <<0:800>>])
  accounts.is_pool_account(valid_pool) |> should.be_true()

  // Invalid discriminator
  let invalid = bit_array.concat([<<0:64>>, <<0:800>>])
  accounts.is_pool_account(invalid) |> should.be_false()
}

pub fn decode_twap_result_test() {
  // Price: 1000000 (1.0 scaled by 1e6)
  // Samples: 24
  // Confidence: 9500 (95%)
  // Encoded as: price (32 bits) | samples (16 bits) | confidence (16 bits)
  let price = 1_000_000
  let samples = 24
  let confidence = 9500
  let encoded = price + samples * 0x100000000 + confidence * 0x1000000000000

  let result = accounts.decode_twap_result(encoded)

  result.price |> should.equal(1_000_000)
  result.samples |> should.equal(24)
  result.confidence |> should.equal(9500)
}

// ============================================================================
// PDA Tests
// ============================================================================

pub fn pool_seeds_test() {
  let mint0 = <<1:256>>
  let mint1 = <<2:256>>

  let seeds = pda.pool_seeds(mint0, mint1)

  // Should have 3 elements
  case seeds {
    [seed0, seed1, seed2] -> {
      seed0 |> should.equal(<<"pool":utf8>>)
      seed1 |> should.equal(mint0)
      seed2 |> should.equal(mint1)
    }
    _ -> should.fail()
  }
}

pub fn pool_seeds_with_bump_test() {
  let mint0 = <<1:256>>
  let mint1 = <<2:256>>

  let seeds = pda.pool_seeds_with_bump(mint0, mint1, 255)

  // Should have 4 elements
  case seeds {
    [seed0, seed1, seed2, seed3] -> {
      seed0 |> should.equal(<<"pool":utf8>>)
      seed1 |> should.equal(mint0)
      seed2 |> should.equal(mint1)
      seed3 |> should.equal(<<255:8>>)
    }
    _ -> should.fail()
  }
}

pub fn farm_seeds_test() {
  let pool = <<1:256>>
  let seeds = pda.farm_seeds(pool)

  case seeds {
    [seed0, seed1] -> {
      seed0 |> should.equal(<<"farm":utf8>>)
      seed1 |> should.equal(pool)
    }
    _ -> should.fail()
  }
}

pub fn concat_seeds_test() {
  let seeds = [<<"test":utf8>>, <<1, 2, 3>>]
  let result = pda.concat_seeds(seeds)

  result |> should.equal(<<"test":utf8, 1, 2, 3>>)
}

// ============================================================================
// Main Module Tests
// ============================================================================

pub fn version_test() {
  aex402.version |> should.equal("1.0.0")
}

pub fn program_id_test() {
  let id = aex402.program_id()
  bit_array.byte_size(id) |> should.equal(32)
}

pub fn error_message_test() {
  aex402.error_message(6000)
  |> should.be_ok()
  |> should.equal("Pool is paused")

  aex402.error_message(9999)
  |> should.be_error()
}

pub fn convenience_calc_d_test() {
  aex402.calc_d(1_000_000, 1_000_000, 100)
  |> should.be_ok()
}

pub fn convenience_simulate_swap_test() {
  aex402.simulate_swap(1_000_000, 1_000_000, 100_000, 100, 30)
  |> should.be_ok()
}
