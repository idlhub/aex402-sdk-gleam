# AeX402 Gleam SDK

Gleam SDK for the AeX402 Hybrid StableSwap AMM on Solana.

## Overview

This SDK provides Gleam bindings for interacting with the AeX402 AMM program, a high-performance hybrid AMM supporting both stable pools (AeX402 curve) and volatile pools (constant product).

**Program ID (Devnet):** `3AMM53MsJZy2Jvf7PeHHga3bsGjWV4TSaYz29WUtcdje`

## Installation

Add to your `gleam.toml`:

```toml
[dependencies]
aex402_sdk = { path = "../path/to/aex402_sdk" }
```

Or publish to Hex and use:

```toml
[dependencies]
aex402_sdk = ">= 1.0.0"
```

## Modules

### `aex402/constants`

Program constants, instruction discriminators, and error codes.

```gleam
import aex402/constants

// Pool constraints
constants.min_amp      // 1
constants.max_amp      // 100,000
constants.default_fee_bps  // 30 (0.3%)
constants.max_tokens   // 8

// Error handling
case constants.error_from_code(6004) {
  Ok(error) -> constants.error_message(error)  // "Slippage exceeded"
  Error(_) -> "Unknown error"
}
```

### `aex402/types`

Type definitions for all account structures.

```gleam
import aex402/types.{Pool, NPool, Farm, Candle, SwapSimpleArgs}

// Decode a candle
let candle = Candle(open: 1_000_000, high_d: 50_000, low_d: 30_000, close_d: 10_000, volume: 5000)
let decoded = types.decode_candle(candle)
// decoded.high = 1_050_000, decoded.low = 970_000
```

### `aex402/accounts`

Binary parsing functions using BitArray pattern matching.

```gleam
import aex402/accounts

// Parse a pool from account data
case accounts.parse_pool(account_data) {
  Ok(pool) -> {
    io.println("Pool amp: " <> int.to_string(pool.amp))
    io.println("Balance 0: " <> int.to_string(pool.bal0))
    io.println("Balance 1: " <> int.to_string(pool.bal1))
  }
  Error(_) -> io.println("Failed to parse pool")
}

// Check account type
accounts.is_pool_account(data)      // Bool
accounts.is_farm_account(data)      // Bool
accounts.is_lottery_account(data)   // Bool
```

### `aex402/instructions`

Build instruction data as BitArrays.

```gleam
import aex402/instructions
import aex402/types.{SwapSimpleArgs, AddLiqArgs}

// Build swap instruction
let args = SwapSimpleArgs(amount_in: 1_000_000_000, min_out: 990_000_000)
let instruction_data = instructions.build_swap_t0_t1(args)

// Build add liquidity instruction
let liq_args = AddLiqArgs(amount0: 1_000_000, amount1: 1_000_000, min_lp: 1_900_000)
let add_liq_data = instructions.build_add_liquidity(liq_args)

// Admin instructions
let pause_data = instructions.build_set_pause(True)
let fee_data = instructions.build_update_fee(types.UpdateFeeArgs(fee_bps: 50))
```

### `aex402/math`

StableSwap calculations using Newton's method.

```gleam
import aex402/math

// Calculate invariant D
case math.calc_d(1_000_000_000, 1_000_000_000, 100) {
  Ok(d) -> io.println("Invariant D: " <> int.to_string(d))
  Error(_) -> io.println("Failed to converge")
}

// Simulate a swap
case math.simulate_swap(
  bal_in: 1_000_000_000,
  bal_out: 1_000_000_000,
  amount_in: 100_000_000,
  amp: 100,
  fee_bps: 30,
) {
  Ok(amount_out) -> io.println("Output: " <> int.to_string(amount_out))
  Error(_) -> io.println("Swap simulation failed")
}

// Calculate LP tokens for deposit
case math.calc_lp_tokens(amt0, amt1, bal0, bal1, lp_supply, amp) {
  Ok(lp_tokens) -> lp_tokens
  Error(_) -> 0
}

// Calculate withdrawal amounts
case math.calc_withdraw(lp_amount, bal0, bal1, lp_supply) {
  Ok(#(amt0, amt1)) -> #(amt0, amt1)
  Error(_) -> #(0, 0)
}

// Get current amp during ramping
let current_amp = math.get_current_amp(amp, target_amp, ramp_start, ramp_end, now)

// Calculate minimum output with slippage
let min_out = math.calc_min_output(expected_output, slippage_bps: 100)  // 1% slippage
```

### `aex402/pda`

PDA seed construction helpers.

```gleam
import aex402/pda

// Build pool PDA seeds
let seeds = pda.pool_seeds(mint0, mint1)

// With bump for signing
let signing_seeds = pda.pool_seeds_with_bump(mint0, mint1, 255)

// Other PDAs
let farm_seeds = pda.farm_seeds(pool_pubkey)
let user_farm_seeds = pda.user_farm_seeds(farm_pubkey, user_pubkey)
let lottery_seeds = pda.lottery_seeds(pool_pubkey)
```

## Target Platforms

Gleam compiles to both Erlang and JavaScript:

```toml
# For Erlang/BEAM
target = "erlang"

# For JavaScript/Node.js
target = "javascript"
```

## Testing

```bash
gleam test
```

## Example: Full Swap Flow

```gleam
import aex402
import aex402/math
import aex402/types.{SwapSimpleArgs}
import aex402/instructions
import aex402/accounts

pub fn prepare_swap(
  pool_data: BitArray,
  amount_in: Int,
  slippage_bps: Int,
) -> Result(BitArray, String) {
  // Parse pool state
  use pool <- result.try(
    accounts.parse_pool(pool_data)
    |> result.map_error(fn(_) { "Failed to parse pool" })
  )

  // Check pool is not paused
  case pool.paused {
    True -> Error("Pool is paused")
    False -> {
      // Simulate swap to get expected output
      use expected_out <- result.try(
        math.simulate_swap(
          pool.bal0,
          pool.bal1,
          amount_in,
          pool.amp,
          pool.fee_bps,
        )
        |> result.map_error(fn(_) { "Swap simulation failed" })
      )

      // Calculate minimum output with slippage
      let min_out = math.calc_min_output(expected_out, slippage_bps)

      // Build instruction data
      let args = SwapSimpleArgs(amount_in: amount_in, min_out: min_out)
      Ok(instructions.build_swap_t0_t1(args))
    }
  }
}
```

## Architecture Notes

- **BitArray**: Gleam's native binary type for efficient parsing
- **Result types**: All parsing and math operations return `Result` for safety
- **Newton's method**: Max 255 iterations for invariant/output calculations
- **Little-endian**: All multi-byte integers are little-endian (Solana convention)

## Contributing

1. Fork the repository
2. Create a feature branch
3. Add tests for new functionality
4. Submit a pull request

## License

MIT
