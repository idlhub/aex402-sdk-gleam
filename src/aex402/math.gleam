//// AeX402 SDK Math Module
////
//// StableSwap math for off-chain simulation.
//// Implements Newton's method iteration for calculating invariant D and output amount Y.
//// All calculations use arbitrary precision integers.

import gleam/int
import gleam/result
import aex402/constants

// ============================================================================
// Constants
// ============================================================================

/// Fee denominator (10000 = 100%)
const fee_denominator = 10_000

// ============================================================================
// Newton's Method Iteration for Invariant D (2-token pool)
// ============================================================================

/// Calculate invariant D for 2-token pool using Newton's method
/// Returns Ok(d) on convergence, Error(Nil) if fails to converge
pub fn calc_d(x: Int, y: Int, amp: Int) -> Result(Int, Nil) {
  let s = x + y
  case s == 0 {
    True -> Ok(0)
    False -> {
      // A * n^n where n=2
      let ann = amp * 4
      calc_d_iterate(x, y, s, ann, s, constants.newton_iterations)
    }
  }
}

fn calc_d_iterate(
  x: Int,
  y: Int,
  s: Int,
  ann: Int,
  d: Int,
  remaining: Int,
) -> Result(Int, Nil) {
  case remaining {
    0 -> Error(Nil)
    _ -> {
      // d_p = d^3 / (4 * x * y)
      let d_p1 = d * d / { x * 2 }
      let d_p = d_p1 * d / { y * 2 }

      // d_new = (ann * s + d_p * 2) * d / ((ann - 1) * d + 3 * d_p)
      let numerator = { ann * s + d_p * 2 } * d
      let denominator = { ann - 1 } * d + d_p * 3

      case denominator == 0 {
        True -> Error(Nil)
        False -> {
          let d_new = numerator / denominator

          // Check convergence
          let diff = case d_new > d {
            True -> d_new - d
            False -> d - d_new
          }

          case diff <= 1 {
            True -> Ok(d_new)
            False -> calc_d_iterate(x, y, s, ann, d_new, remaining - 1)
          }
        }
      }
    }
  }
}

// ============================================================================
// Newton's Method Iteration for Output Amount Y
// ============================================================================

/// Calculate output amount y given input x for swap using Newton's method
/// Returns Ok(y) on convergence, Error(Nil) if fails to converge
pub fn calc_y(x_new: Int, d: Int, amp: Int) -> Result(Int, Nil) {
  let ann = amp * 4

  // c = d^3 / (4 * x_new * ann)
  let c1 = d * d / { x_new * 2 }
  let c = c1 * d / { ann * 2 }

  // b = x_new + d / ann
  let b = x_new + d / ann

  calc_y_iterate(d, c, b, d, constants.newton_iterations)
}

fn calc_y_iterate(
  d: Int,
  c: Int,
  b: Int,
  y: Int,
  remaining: Int,
) -> Result(Int, Nil) {
  case remaining {
    0 -> Error(Nil)
    _ -> {
      // y_new = (y^2 + c) / (2y + b - d)
      let numerator = y * y + c
      let denominator = y * 2 + b - d

      case denominator <= 0 {
        True -> Error(Nil)
        False -> {
          let y_new = numerator / denominator

          // Check convergence
          let diff = case y_new > y {
            True -> y_new - y
            False -> y - y_new
          }

          case diff <= 1 {
            True -> Ok(y_new)
            False -> calc_y_iterate(d, c, b, y_new, remaining - 1)
          }
        }
      }
    }
  }
}

// ============================================================================
// Swap Simulation
// ============================================================================

/// Simulate a swap and return output amount after fee
pub fn simulate_swap(
  bal_in: Int,
  bal_out: Int,
  amount_in: Int,
  amp: Int,
  fee_bps: Int,
) -> Result(Int, Nil) {
  use d <- result.try(calc_d(bal_in, bal_out, amp))
  let new_bal_in = bal_in + amount_in
  use new_bal_out <- result.try(calc_y(new_bal_in, d, amp))

  let amount_out_before_fee = bal_out - new_bal_out

  // Apply fee
  let fee = amount_out_before_fee * fee_bps / fee_denominator
  let amount_out = amount_out_before_fee - fee

  Ok(amount_out)
}

/// Simulate a swap and return output amount without fee (for migration)
pub fn simulate_swap_no_fee(
  bal_in: Int,
  bal_out: Int,
  amount_in: Int,
  amp: Int,
) -> Result(Int, Nil) {
  use d <- result.try(calc_d(bal_in, bal_out, amp))
  let new_bal_in = bal_in + amount_in
  use new_bal_out <- result.try(calc_y(new_bal_in, d, amp))
  Ok(bal_out - new_bal_out)
}

// ============================================================================
// LP Token Calculations
// ============================================================================

/// Calculate LP tokens for deposit (2-token pool)
pub fn calc_lp_tokens(
  amt0: Int,
  amt1: Int,
  bal0: Int,
  bal1: Int,
  lp_supply: Int,
  amp: Int,
) -> Result(Int, Nil) {
  case lp_supply == 0 {
    True -> {
      // Initial deposit: LP = sqrt(amt0 * amt1)
      let product = amt0 * amt1
      Ok(isqrt(product))
    }
    False -> {
      use d0 <- result.try(calc_d(bal0, bal1, amp))
      use d1 <- result.try(calc_d(bal0 + amt0, bal1 + amt1, amp))

      case d0 == 0 {
        True -> Error(Nil)
        False -> {
          // LP tokens = lp_supply * (d1 - d0) / d0
          Ok(lp_supply * { d1 - d0 } / d0)
        }
      }
    }
  }
}

/// Calculate tokens received for LP burn
pub fn calc_withdraw(
  lp_amount: Int,
  bal0: Int,
  bal1: Int,
  lp_supply: Int,
) -> Result(#(Int, Int), Nil) {
  case lp_supply == 0 {
    True -> Error(Nil)
    False -> {
      let amount0 = bal0 * lp_amount / lp_supply
      let amount1 = bal1 * lp_amount / lp_supply
      Ok(#(amount0, amount1))
    }
  }
}

// ============================================================================
// Amp Ramping
// ============================================================================

/// Calculate current amp during ramping
pub fn get_current_amp(
  amp: Int,
  target_amp: Int,
  ramp_start: Int,
  ramp_end: Int,
  now: Int,
) -> Int {
  case now >= ramp_end || ramp_end == ramp_start {
    True -> target_amp
    False ->
      case now <= ramp_start {
        True -> amp
        False -> {
          let elapsed = now - ramp_start
          let duration = ramp_end - ramp_start

          case target_amp > amp {
            True -> {
              let diff = target_amp - amp
              amp + diff * elapsed / duration
            }
            False -> {
              let diff = amp - target_amp
              amp - diff * elapsed / duration
            }
          }
        }
      }
  }
}

// ============================================================================
// Price Impact
// ============================================================================

/// Calculate price impact for a swap (returns fraction * 1e9)
pub fn calc_price_impact(
  bal_in: Int,
  bal_out: Int,
  amount_in: Int,
  amp: Int,
  fee_bps: Int,
) -> Result(Int, Nil) {
  use amount_out <- result.try(simulate_swap(
    bal_in,
    bal_out,
    amount_in,
    amp,
    fee_bps,
  ))

  // Price impact = 1 - (amount_out / amount_in) in 1e9 units
  let ratio = amount_out * 1_000_000_000 / amount_in
  Ok(1_000_000_000 - ratio)
}

// ============================================================================
// Slippage Tolerance
// ============================================================================

/// Calculate minimum output with slippage tolerance
pub fn calc_min_output(expected_output: Int, slippage_bps: Int) -> Int {
  expected_output * { fee_denominator - slippage_bps } / fee_denominator
}

// ============================================================================
// Virtual Price
// ============================================================================

/// Calculate virtual price (LP value relative to underlying)
/// Returns price * 1e18 for precision
pub fn calc_virtual_price(
  bal0: Int,
  bal1: Int,
  lp_supply: Int,
  amp: Int,
) -> Result(Int, Nil) {
  case lp_supply == 0 {
    True -> Error(Nil)
    False -> {
      use d <- result.try(calc_d(bal0, bal1, amp))
      // Virtual price = D * 1e18 / lpSupply
      let precision = 1_000_000_000_000_000_000
      Ok(d * precision / lp_supply)
    }
  }
}

// ============================================================================
// Imbalance Check
// ============================================================================

/// Check if pool balances are within acceptable imbalance ratio
pub fn check_imbalance(
  bal0: Int,
  bal1: Int,
  max_imbalance_ratio: Int,
) -> Bool {
  case bal0 == 0 || bal1 == 0 {
    True -> False
    False -> {
      let ratio = case bal0 > bal1 {
        True -> bal0 * 100 / bal1
        False -> bal1 * 100 / bal0
      }
      ratio <= max_imbalance_ratio * 100
    }
  }
}

// ============================================================================
// Integer Square Root (Newton's method)
// ============================================================================

/// Integer square root using Newton's method
pub fn isqrt(n: Int) -> Int {
  case n {
    0 -> 0
    1 -> 1
    2 -> 1
    3 -> 1
    _ -> isqrt_iterate(n, n)
  }
}

fn isqrt_iterate(n: Int, x: Int) -> Int {
  let y = { x + n / x } / 2
  case y < x {
    True -> isqrt_iterate(n, y)
    False -> x
  }
}

// ============================================================================
// N-Token Pool Math
// ============================================================================

/// Calculate invariant D for N-token pool
pub fn calc_d_n(balances: List(Int), amp: Int) -> Result(Int, Nil) {
  let n = list_length(balances)
  case n == 0 {
    True -> Ok(0)
    False -> {
      let s = list_sum(balances)
      case s == 0 {
        True -> Ok(0)
        False -> {
          // A * n^n
          let ann = amp * pow_int(n, n)
          calc_d_n_iterate(balances, s, ann, n, s, constants.newton_iterations)
        }
      }
    }
  }
}

fn calc_d_n_iterate(
  balances: List(Int),
  s: Int,
  ann: Int,
  n: Int,
  d: Int,
  remaining: Int,
) -> Result(Int, Nil) {
  case remaining {
    0 -> Error(Nil)
    _ -> {
      // d_p = d^(n+1) / (n^n * prod(balances))
      let d_p = calc_d_p(balances, d, n)

      // d_new = (ann * s + d_p * n) * d / ((ann - 1) * d + (n + 1) * d_p)
      let numerator = { ann * s + d_p * n } * d
      let denominator = { ann - 1 } * d + { n + 1 } * d_p

      case denominator == 0 {
        True -> Error(Nil)
        False -> {
          let d_new = numerator / denominator

          let diff = case d_new > d {
            True -> d_new - d
            False -> d - d_new
          }

          case diff <= 1 {
            True -> Ok(d_new)
            False ->
              calc_d_n_iterate(balances, s, ann, n, d_new, remaining - 1)
          }
        }
      }
    }
  }
}

fn calc_d_p(balances: List(Int), d: Int, n: Int) -> Int {
  calc_d_p_acc(balances, d, n, d)
}

fn calc_d_p_acc(balances: List(Int), d: Int, n: Int, acc: Int) -> Int {
  case balances {
    [] -> acc
    [bal, ..rest] -> {
      let new_acc = acc * d / { bal * n }
      calc_d_p_acc(rest, d, n, new_acc)
    }
  }
}

/// Calculate output amount y for N-token pool swap
pub fn calc_y_n(
  balances: List(Int),
  out_idx: Int,
  d: Int,
  amp: Int,
) -> Result(Int, Nil) {
  let n = list_length(balances)
  let ann = amp * pow_int(n, n)

  // Sum of all balances except out_idx
  let s_without = list_sum_except(balances, out_idx, 0, 0)

  // c = d^(n+1) / (n^n * ann * prod(balances except out))
  let prod_without = list_prod_except(balances, out_idx, 0, 1)
  let c = calc_c_n(d, n, ann, prod_without)

  // b = s_without + d / ann
  let b = s_without + d / ann

  calc_y_iterate(d, c, b, d, constants.newton_iterations)
}

fn calc_c_n(d: Int, n: Int, ann: Int, prod: Int) -> Int {
  let nn = pow_int(n, n)
  d * d / { prod * nn * ann }
}

// ============================================================================
// Helper Functions
// ============================================================================

fn list_length(list: List(a)) -> Int {
  list_length_acc(list, 0)
}

fn list_length_acc(list: List(a), acc: Int) -> Int {
  case list {
    [] -> acc
    [_, ..rest] -> list_length_acc(rest, acc + 1)
  }
}

fn list_sum(list: List(Int)) -> Int {
  list_sum_acc(list, 0)
}

fn list_sum_acc(list: List(Int), acc: Int) -> Int {
  case list {
    [] -> acc
    [x, ..rest] -> list_sum_acc(rest, acc + x)
  }
}

fn list_sum_except(list: List(Int), skip_idx: Int, current_idx: Int, acc: Int) -> Int {
  case list {
    [] -> acc
    [x, ..rest] ->
      case current_idx == skip_idx {
        True -> list_sum_except(rest, skip_idx, current_idx + 1, acc)
        False -> list_sum_except(rest, skip_idx, current_idx + 1, acc + x)
      }
  }
}

fn list_prod_except(
  list: List(Int),
  skip_idx: Int,
  current_idx: Int,
  acc: Int,
) -> Int {
  case list {
    [] -> acc
    [x, ..rest] ->
      case current_idx == skip_idx {
        True -> list_prod_except(rest, skip_idx, current_idx + 1, acc)
        False -> list_prod_except(rest, skip_idx, current_idx + 1, acc * x)
      }
  }
}

fn pow_int(base: Int, exp: Int) -> Int {
  pow_int_acc(base, exp, 1)
}

fn pow_int_acc(base: Int, exp: Int, acc: Int) -> Int {
  case exp {
    0 -> acc
    _ -> pow_int_acc(base, exp - 1, acc * base)
  }
}
