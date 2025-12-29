//// AeX402 SDK - Gleam SDK for the AeX402 Hybrid StableSwap AMM on Solana
////
//// This SDK provides:
//// - Constants: Program ID, discriminators, error codes
//// - Types: Pool, NPool, Farm, Lottery, etc.
//// - Accounts: Binary parsing functions using BitArray
//// - Instructions: Instruction data builders
//// - Math: StableSwap calculations (calc_d, calc_y, simulate_swap)
//// - PDA: Program Derived Address utilities
////
//// ## Example Usage
////
//// ```gleam
//// import aex402
//// import aex402/math
//// import aex402/types.{SwapSimpleArgs}
//// import aex402/instructions
////
//// // Simulate a swap
//// let result = math.simulate_swap(
////   bal_in: 1_000_000_000,
////   bal_out: 1_000_000_000,
////   amount_in: 100_000_000,
////   amp: 100,
////   fee_bps: 30,
//// )
////
//// // Build swap instruction data
//// let args = SwapSimpleArgs(amount_in: 100_000_000, min_out: 99_000_000)
//// let instruction_data = instructions.build_swap_t0_t1(args)
//// ```

// Re-export all submodules
import aex402/constants
import aex402/types
import aex402/accounts
import aex402/instructions
import aex402/math
import aex402/pda

// ============================================================================
// Version Information
// ============================================================================

/// SDK version
pub const version = "1.0.0"

/// Program name
pub const program_name = "AeX402 Hybrid StableSwap AMM"

/// Target network (devnet)
pub const network = "devnet"

// ============================================================================
// Convenience Re-exports
// ============================================================================

/// Get the program ID bytes
pub fn program_id() -> BitArray {
  constants.program_id_bytes
}

/// Parse pool account from binary data
pub fn parse_pool(data: BitArray) -> Result(types.Pool, Nil) {
  accounts.parse_pool(data)
}

/// Parse N-token pool account from binary data
pub fn parse_npool(data: BitArray) -> Result(types.NPool, Nil) {
  accounts.parse_npool(data)
}

/// Parse farm account from binary data
pub fn parse_farm(data: BitArray) -> Result(types.Farm, Nil) {
  accounts.parse_farm(data)
}

/// Parse user farm account from binary data
pub fn parse_user_farm(data: BitArray) -> Result(types.UserFarm, Nil) {
  accounts.parse_user_farm(data)
}

/// Parse lottery account from binary data
pub fn parse_lottery(data: BitArray) -> Result(types.Lottery, Nil) {
  accounts.parse_lottery(data)
}

/// Parse lottery entry account from binary data
pub fn parse_lottery_entry(data: BitArray) -> Result(types.LotteryEntry, Nil) {
  accounts.parse_lottery_entry(data)
}

/// Calculate invariant D for 2-token pool
pub fn calc_d(x: Int, y: Int, amp: Int) -> Result(Int, Nil) {
  math.calc_d(x, y, amp)
}

/// Calculate output amount Y
pub fn calc_y(x_new: Int, d: Int, amp: Int) -> Result(Int, Nil) {
  math.calc_y(x_new, d, amp)
}

/// Simulate a swap
pub fn simulate_swap(
  bal_in: Int,
  bal_out: Int,
  amount_in: Int,
  amp: Int,
  fee_bps: Int,
) -> Result(Int, Nil) {
  math.simulate_swap(bal_in, bal_out, amount_in, amp, fee_bps)
}

/// Get error message for error code
pub fn error_message(code: Int) -> Result(String, Nil) {
  case constants.error_from_code(code) {
    Ok(error) -> Ok(constants.error_message(error))
    Error(_) -> Error(Nil)
  }
}

// ============================================================================
// Quick Reference
// ============================================================================

/// Pool size in bytes
pub const pool_size = constants.pool_size

/// NPool size in bytes
pub const npool_size = constants.npool_size

/// Maximum tokens in an N-pool
pub const max_tokens = constants.max_tokens

/// Minimum amplification coefficient
pub const min_amp = constants.min_amp

/// Maximum amplification coefficient
pub const max_amp = constants.max_amp

/// Default swap fee in basis points
pub const default_fee_bps = constants.default_fee_bps

/// Newton's method maximum iterations
pub const newton_iterations = constants.newton_iterations
