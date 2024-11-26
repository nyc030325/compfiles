/-
Copyright (c) 2024 The Compfiles Contributors. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: InternLM-MATH LEAN Formalizer v0.1
-/

import Mathlib.Tactic

import ProblemExtraction

problem_file { tags := [.NumberTheory] }

/-!
# International Mathematical Olympiad 1978, Problem 1

m and n are positive integers with m < n.
The last three decimal digits of 1978ᵐ are the same as the
last three decimal digits of 1978ⁿ.
Find m and n such that m + n has the least possible value.
-/

namespace Imo1978P1

determine solution : ℕ × ℕ := (3, 103)

abbrev ValidPair : ℕ × ℕ → Prop
| (m, n) => 1 ≤ m ∧ m < n ∧ (1978^m) % 1000 = (1978^n) % 1000

problem imo1978_p1 (m n : ℕ)
    (hmn : (m, n) = solution) :
    ValidPair (m, n) ∧
    (∀ m' n' : ℕ, ValidPair (m', n') → m + n ≤ m' + n') := by
  -- We follow the informal solution at
  -- https://prase.cz/kalva/imo/isoln/isoln781.html
  constructor
  · rw [hmn, solution, ValidPair]
    norm_num
  intro m' n' hmn'
  -- We require 1978^m'(1978^(n'-m') - 1) to be a multiple of 1000=8·125.
  dsimp only [ValidPair] at hmn'
  obtain ⟨h1, h2, h3⟩ := hmn'
  change _ ≡ _ [MOD 1000] at h3
  rw [Nat.modEq_iff_dvd] at h3
  push_cast at h3
  replace h3 : (1000:ℤ) ∣ 1978 ^ m' * (1978 ^ (n' - m') - 1) := by
    rw [mul_sub, mul_one]
    rwa [pow_mul_pow_sub 1978 (Nat.le_of_succ_le h2)]
  rw [show (1000 : ℤ) = 8 * 125 by norm_num] at h3

  -- So we must have 8 divides 1978^m',
  have h4 : (8 : ℤ) ∣ 1978 ^ m' := by
    replace h3 : (8:ℤ) ∣ 1978 ^ m' * (1978 ^ (n' - m') - 1) :=
      dvd_of_mul_right_dvd h3
    have h5 : IsCoprime (8 : ℤ) (1978 ^ (n' - m') - 1) := by
      rw [show (8 : ℤ) = 2 ^ 3 by norm_num]
      suffices H : IsCoprime (2 : ℤ) (1978 ^ (n' - m')- 1) from
        IsCoprime.pow_left H
      suffices H : ¬ (2:ℤ) ∣ (1978 ^ (n' - m') - 1) from
        (Prime.coprime_iff_not_dvd Int.prime_two).mpr H
      rw [Int.two_dvd_ne_zero]
      have h6 : 1 ≤ (1978 ^ (n' - m')) := Nat.one_le_pow' (n' - m') 1977
      rw [show (1978 : ℤ) = 2 * 989 by norm_num]
      have h7 : (((2:ℤ) * 989) ^ (n' - m')) % 2 = 0 := by
        rw [mul_pow]
        obtain ⟨c, hc⟩ : ∃ c, c = (n' - m') := exists_eq
        cases' c with c
        · omega
        · rw [←hc, pow_succ', mul_assoc]
          exact Int.mul_emod_right _ _
      rw [Int.sub_emod, h7]
      norm_num
    exact IsCoprime.dvd_of_dvd_mul_right h5 h3

  -- and hence m ≥ 3
  have h5 : 3 ≤ m' := by
    rw [show (1978 : ℤ) = 2 * 989 by norm_num] at h4
    rw [show (8 : ℤ) = 2 ^ 3 by norm_num] at h4
    rw [mul_pow] at h4
    have h6 : IsCoprime ((2:ℤ)^3) (989 ^ m') := by
      suffices H : IsCoprime (2:ℤ) (989 ^ m') from IsCoprime.pow_left H
      rw [Prime.coprime_iff_not_dvd Int.prime_two, Int.two_dvd_ne_zero]
      rw [←Int.odd_iff, Int.odd_pow]
      exact Or.inl ⟨494, rfl⟩
    replace h4 := IsCoprime.dvd_of_dvd_mul_right h6 h4
    obtain ⟨c, hc⟩ := h4
    have hc' := hc
    apply_fun (fun x => multiplicity 2 x) at hc
    have hf : multiplicity.Finite 2 (2 ^ 3 * c) := by
      apply multiplicity.finite_prime_left Int.prime_two
      simp only [Int.reducePow, ne_eq, mul_eq_zero, OfNat.ofNat_ne_zero, false_or]
      rintro rfl
      simp at hc'
    rw [multiplicity_mul Int.prime_two hf] at hc
    rw [multiplicity_pow_self (by norm_num) (by decide)] at hc
    rw [multiplicity_pow_self (by norm_num) (by decide)] at hc
    omega

  -- and 125 divides 1978^(n'-m') - 1.
  have h6 : (125 : ℤ) ∣ 1978^(n'-m') - 1 := by
    obtain ⟨k, hk⟩ : ∃ k, k + 3 = m' := ⟨m' - 3, by omega⟩
    rw [←hk] at h4
    nth_rw 1 [←hk] at h3
    have h7 : (1978:ℤ) ^ (k + 3) * (1978 ^ (n' - m') - 1) =
        8 * (1978 ^ k * 989 ^ 3 * (1978 ^ (n' - m') - 1)) := by ring
    rw [h7] at h3
    rw [dvd_cancel_left_mem_nonZeroDivisors (mem_nonZeroDivisors_of_ne_zero (by norm_num))] at h3
    have h8 : IsCoprime (125 : ℤ) (1978 ^ k) := IsCoprime.pow_right (by norm_num)
    have h9 : IsCoprime (125 : ℤ) (989 ^ 3) := by norm_num
    rw [mul_assoc] at h3
    replace h3 := IsCoprime.dvd_of_dvd_mul_left h8 h3
    exact IsCoprime.dvd_of_dvd_mul_left h9 h3

  rw [Prod.mk.injEq] at hmn
  obtain ⟨rfl, rfl⟩ := hmn

  -- By Euler's theorem, 1978^φ(125) = 1 (mod 125).
  -- φ(125) = 125 - 25 = 100, so, 1978^100 = 1 (mod 125).
  have h8 : Nat.Coprime 1978 125 := by norm_num
  have h9 := Nat.ModEq.pow_totient h8
  rw [show Nat.totient 125 = 100 from rfl] at h9

  -- Hence the smallest r such that 1978^r = 1 (mod 125) must be a divisor of 100
  -- (because if it was not, then the remainder on dividing it into 100 would give a smaller r).
  let r := n' - m'
  have h10 : r ∣ 100 := by
    sorry

  have h11 : r ∈ Nat.divisors 100 := by
    rw [Nat.mem_divisors]
    exact ⟨h10, by norm_num⟩

  have h12 : Nat.divisors 100 = {1,2,4,5,10,20,25,50,100} := by decide
  rw [h12] at h11; clear h12
  simp only [Finset.mem_insert, Finset.mem_singleton] at h11
  change 125 ∣ 1978 ^ r - 1 at h6
  obtain hr1 | hr2 | hr4 | hr5 | hr10 | hr20 | hr25 | hr50 | hr100 := h11
  · rw [hr1] at h6; norm_num at h6
  · rw [hr2] at h6; norm_num at h6
  · rw [hr4] at h6; norm_num at h6
  · rw [hr5] at h6; norm_num at h6
  · rw [hr10] at h6; norm_num at h6
  · rw [hr20] at h6; norm_num at h6
  · rw [hr25] at h6; norm_num at h6
  · rw [hr50] at h6; norm_num at h6
  · omega

end Imo1978P1
