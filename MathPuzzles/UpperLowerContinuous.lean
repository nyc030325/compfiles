import Mathlib.Algebra.Ring.Equiv
import Mathlib.Data.Real.Basic
import Mathlib.Data.Set.Intervals.Basic
import Mathlib.Topology.Order
import Mathlib.Topology.MetricSpace.Basic
import Mathlib.Topology.Algebra.Ring.Basic
import Mathlib.Topology.Bases

import Mathlib.Tactic.LibrarySearch
import Mathlib.Tactic.Linarith

/-
Suppose f : ℝ -> ℝ is continuous in both the upper topology (where
the basic open sets are half-open intervals (a, b]) and lower topology
(where the basic open sets are half-open intervals [a,b)).
Then f is continuous in the usual topology (where the basic open sets are
open intervals (a,b)) and also monotone nondecreasing.
-/

namespace UpperLowerContinuous

/--
 Let S be a set of real numbers such that:
  1. If x ∈ S, then we can find y > x such that [x, y) ⊆ S.
  2. If [x, y) ⊆ S, then y ∈ S.
 Then, given z ∈ S, we have [z, ∞) ⊆ S.
-/
lemma real_induction
    {S : Set ℝ}
    (h1 : ∀ x ∈ S, ∃ y, x < y ∧ Set.Ico x y ⊆ S)
    (h2 : ∀ x ∈ S, ∀ y, x < y → Set.Ico x y ⊆ S → y ∈ S)
    {z : ℝ}
    (hz : z ∈ S)
    : Set.Ici z ⊆ S := by

  -- Suppose not. Then there is w₁ in [z,∞) that is not in S.
  by_contra H; rw[Set.subset_def] at H; push_neg at H
  obtain ⟨w₁, hw₁, hw₁'⟩ := H

  -- Take the set W = {w | z ≤ w ∧ w ∉ S}.
  let W : Set ℝ := {w | z ≤ w ∧ w ∉ S}

  -- Let w₀ be its greatest lower bound.
  let w₀ := sInf W

  -- W is nonempty.
  have hwne : Set.Nonempty W := ⟨w₁, hw₁, hw₁'⟩

  have h6 : z ∈ lowerBounds W := fun _ ha ↦ ha.1
  have hwbb : BddBelow W := Set.nonempty_of_mem h6

  -- Note that [z, w₀) ⊆ S.
  have h7: Set.Ico z w₀ ⊆ S := by
    intros s₁ hs
    by_contra H
    exact (not_le.mpr hs.2) (csInf_le hwbb ⟨hs.1, H⟩)

  have h9 : ∀ w ∈ W, z ≤ w := fun w h ↦ h.1
  have h10 : z ≤ w₀ := le_csInf hwne h9

  have h13 := Real.is_glb_sInf W hwne hwbb

  have h11 : z ≠ w₀ := by
    by_contra H
    obtain ⟨y, hy1, hy2⟩ := h1 z hz
    rw[H] at hy1 h6

    have h12 : y ∈ lowerBounds W := by
      intros a ha;
      by_contra H'; push_neg at H'
      exact ha.2 (hy2 ⟨h9 a ha, H'⟩)
    exact (not_le.mpr hy1) ((isGLB_iff_le_iff.mp h13 y).mpr h12)

  have h15: z < w₀ := Ne.lt_of_le h11 h10

  -- So we can apply h2, to get that w₀ ∈ S.
  have h8 := h2 z hz w₀ h15 h7

  -- Then we can apply h1 to get some y
  -- such that w₀ < y and Set.Ico w₀ y ⊆ S.

  obtain ⟨y, hwy, hy⟩ := h1 w₀ h8

  have h12 : y ∈ lowerBounds W := by
    intros a ha;
    by_contra H'; push_neg at H'
    apply ha.2
    obtain hlt | hle := lt_or_le a w₀
    · exact h7 ⟨ha.1, hlt⟩
    · exact hy ⟨hle, H'⟩

  exact (not_le.mpr hwy) ((isGLB_iff_le_iff.mp h13 y).mpr h12)

def upper_intervals : Set (Set ℝ) := {s : Set ℝ | ∃ a b : ℝ, Set.Ioc a b = s}
def lower_intervals : Set (Set ℝ) := {s : Set ℝ | ∃ a b : ℝ, Set.Ico a b = s}
def open_intervals : Set (Set ℝ) := {s : Set ℝ | ∃ a b : ℝ, Set.Ioo a b = s}

/-- Generate the toplogy on ℝ by intervals of the form (a, b]. -/
def tᵤ : TopologicalSpace ℝ := TopologicalSpace.generateFrom upper_intervals

/-- Generate the toplogy on ℝ by intervals of the form [a, b). -/
def tₗ : TopologicalSpace ℝ := TopologicalSpace.generateFrom lower_intervals

/-- This should be equivalent to the default instance
for `TopologicalSpace ℝ`, which goes through `UniformSpace`, but for
now I don't want to bother with proving that equivalence.
-/
def tₛ : TopologicalSpace ℝ := TopologicalSpace.generateFrom open_intervals

-- activate the Continuous[t1, t2] notation
open Topology

lemma lower_basis :
    @TopologicalSpace.IsTopologicalBasis ℝ tₗ lower_intervals := by
  refine'
   @TopologicalSpace.IsTopologicalBasis.mk ℝ tₗ lower_intervals _ _ rfl
  · intros I1 hI1 I2 hI2 x hx;
    obtain ⟨a, b, hab⟩ := hI1
    obtain ⟨c, d, hcd⟩ := hI2
    use Set.Ico (Sup.sup a c) (Inf.inf b d)
    constructor
    · exact ⟨Sup.sup a c, Inf.inf b d, rfl ⟩
    · constructor
      · aesop
      · intros y hy
        aesop
  · ext x; constructor
    · aesop
    · intro _; apply Set.mem_sUnion.mpr;
      use Set.Ico x (x+1)
      constructor
      · exact ⟨x, x+1, rfl⟩
      · simp

lemma upper_basis :
    @TopologicalSpace.IsTopologicalBasis ℝ tᵤ upper_intervals := by
  refine'
   @TopologicalSpace.IsTopologicalBasis.mk ℝ tᵤ upper_intervals _ _ rfl
  · intros I1 hI1 I2 hI2 x hx;
    obtain ⟨a, b, hab⟩ := hI1
    obtain ⟨c, d, hcd⟩ := hI2
    use Set.Ioc (Sup.sup a c) (Inf.inf b d)
    constructor
    · exact ⟨Sup.sup a c, Inf.inf b d, rfl⟩
    · constructor
      · aesop
      · intros y hy
        aesop
  · ext x; constructor
    · aesop
    · intro _; apply Set.mem_sUnion.mpr
      use Set.Ioc (x-1) x
      constructor
      · exact ⟨x-1, x, rfl⟩
      · simp

lemma open_basis :
    @TopologicalSpace.IsTopologicalBasis ℝ tₛ open_intervals := by
 refine'
   @TopologicalSpace.IsTopologicalBasis.mk ℝ tₛ open_intervals _ _ rfl
 · intros I1 hI1 I2 hI2 x hx
   obtain ⟨a, b, hab⟩ := hI1
   obtain ⟨c, d, hcd⟩ := hI2
   use Set.Ioo (Sup.sup a c) (Inf.inf b d)
   constructor
   · exact ⟨Sup.sup a c, Inf.inf b d, rfl⟩
   · constructor
     · aesop
     · intros y hy; aesop
 · ext x; constructor
   · aesop
   · intro _; apply Set.mem_sUnion.mpr
     use Set.Ioo (x-1) (x+1)
     constructor
     · exact ⟨x-1, x+1, rfl⟩
     · simp

lemma continuous_of_upper_lower_continuous
    (f : ℝ → ℝ)
    (huc : Continuous[tᵤ, tᵤ] f)
    (hlc : Continuous[tₗ, tₗ] f)
    : Continuous[tₛ, tₛ] f := by
  /-
    Let an open set (a,b) be given. Let a point c ∈ f⁻¹(a,b) be given.
    To show f⁻¹(a,b) is open, we must show there's an open interval
    (a',b') containing c, and contained in f⁻¹(a,b). We know f(c) ∈ (a,b),
    so we can consider (a,f(c)] and [f(c),b). Because f is tᵤ- and tₗ-continuous,
     - f⁻¹(a,f(c)] is tᵤ-open
     - f⁻¹[f(c),b) is tₗ-open
    Note that also we know
     - c ∈ f⁻¹(a,f(c)]
     - c ∈ f⁻¹[f(c),b)
    therefore
     - There is a half-open interval (a', c] contained in f⁻¹(a,f(c)]
     - There is a half-open interval [c, b') contained in f⁻¹[f(c),b)
    therefore
     - f(a', c] ⊆ (a,f(c)]
     - f[c, b') ⊆ [f(c),b)
    hence
     f(a',b') ⊆ (a,b)
    as required.
  -/
  apply continuous_generateFrom
  intros ab hab
  obtain ⟨a,b, hab⟩ := hab
  have h6oc : ∀ c ∈ f ⁻¹' ab, ∃ a', Set.Ioc a' c ⊆ f ⁻¹' Set.Ioc a (f c) ∧ (a' < c ∧ a < f c) := by
    intros c hc
    have h2 : IsOpen[tᵤ] (Set.Ioc a (f c)) := by
      apply TopologicalSpace.isOpen_generateFrom_of_mem
      unfold upper_intervals; aesop
    have h3 : IsOpen[tᵤ] (f ⁻¹' (Set.Ioc a (f c))) := by
      apply continuous_def.mp huc
      exact h2
    have h4 : c ∈ f ⁻¹' Set.Ioc a (f c) := by aesop
    have h5 :=
     (@TopologicalSpace.IsTopologicalBasis.isOpen_iff _ tᵤ _
       upper_intervals upper_basis).mp h3 c h4
    obtain ⟨t, ⟨a', c', hac'⟩, htc, ht⟩ := h5
    use a'
    rw[←hac'] at htc
    constructor
    · intros x hx
      have h7 : x ∈ Set.Ioc a' c' := by
          cases' hx with hxl hxr
          constructor
          · exact hxl
          · exact hxr.trans htc.2
      rw [hac'] at h7
      exact ht h7
    · exact ⟨ htc.1, h4.1 ⟩

  have h6co : ∀ c ∈ f ⁻¹' ab, ∃ b', Set.Ico c b' ⊆ f ⁻¹' Set.Ico (f c) b ∧ (c < b' ∧ f c < b) := by
    intros c hc
    have h2 : IsOpen[tₗ] (Set.Ico (f c) b) := by
      apply TopologicalSpace.isOpen_generateFrom_of_mem
      unfold lower_intervals; aesop
    have h3 : IsOpen[tₗ] (f ⁻¹' (Set.Ico (f c) b)) := by
      apply continuous_def.mp hlc
      exact h2
    have h4 : c ∈ f ⁻¹' Set.Ico (f c) b := by aesop
    have h5 :=
     (@TopologicalSpace.IsTopologicalBasis.isOpen_iff _ tₗ _
       lower_intervals lower_basis).mp h3 c h4
    obtain ⟨t, ⟨c', b', hcb'⟩, htc, ht⟩ := h5
    use b'
    rw [←hcb'] at htc
    constructor
    · intros x hx
      have h7 : x ∈ Set.Ico c' b' := by
          cases' hx with hxl hxr
          constructor
          · exact htc.1.trans hxl
          · exact hxr
      rw [hcb'] at h7
      exact ht h7
    · exact ⟨htc.2, h4.2⟩

  have h1 : ∀ c ∈ f ⁻¹' ab, ∃ t, t ∈ open_intervals ∧ c ∈ t ∧ t ⊆ f ⁻¹' ab := by
    intros c hc
    obtain ⟨ a', ha', ⟨ ineq1a, ineq1b⟩ ⟩ := h6oc c hc
    obtain ⟨ b', hb', ⟨ ineq2a, ineq2b⟩ ⟩ := h6co c hc
    use Set.Ioo a' b'
    constructor
    · exact ⟨a', b', rfl⟩
    · constructor
      · aesop
      · have ilem1 := Set.Ioc_union_Ico_eq_Ioo ineq1a ineq2a
        have ilem2 := Set.Ioc_union_Ico_eq_Ioo ineq1b ineq2b
        have subeq :
          Set.Ioc a' c ∪ Set.Ico c b' ⊆ f ⁻¹' Set.Ioc a (f c) ∪ f ⁻¹' Set.Ico (f c) b
          := Set.union_subset_union ha' hb'
        rw [ilem1, ←Set.preimage_union, ilem2, hab] at subeq
        exact subeq
  exact
     (@TopologicalSpace.IsTopologicalBasis.isOpen_iff ℝ tₛ (f ⁻¹' ab)
       open_intervals open_basis).mpr h1

-- [x, ∞) is open in tₗ
lemma infinite_interval_lower_open (x : ℝ) : IsOpen[tₗ] (Set.Ici x) := by
  rw [@TopologicalSpace.IsTopologicalBasis.isOpen_iff
          ℝ tₗ _ lower_intervals lower_basis]
  intros a ha
  -- `Set.Ici x` means the interval [x, ∞).
  -- choose [a, a + 1)
  use Set.Ico a (a + 1)
  constructor
  · unfold lower_intervals; aesop
  · constructor
    · constructor
      · exact Eq.le rfl
      · exact lt_add_one a
    · intros y hy
      cases' hy with hyl hyr
      rw[Set.mem_Ici] at ha
      rw[Set.mem_Ici]
      linarith

-- (-∞, x) is open in tᵤ
lemma infinite_interval_upper_open (x : ℝ) : IsOpen[tᵤ] (Set.Iio x) := by
  -- in tᵤ, open sets are of the form (a, b].
  rw [@TopologicalSpace.IsTopologicalBasis.isOpen_iff
          ℝ tᵤ _ upper_intervals upper_basis]
  intros a ha
  use Set.Ioc (a - 1) a
  constructor
  · unfold upper_intervals; aesop
  · constructor
    · constructor
      · linarith
      · exact Eq.le rfl
    · intros y hy
      cases' hy with hyl hyr
      rw[Set.mem_Iio] at ha
      rw[Set.mem_Iio]
      linarith

#check TopologicalSpace.IsTopologicalBasis.isOpen_iff
-- TopologicalSpace.IsTopologicalBasis.isOpen_iff.{u}
--   {α : Type u} [t : TopologicalSpace α] {s : Set α} {b : Set (Set α)}
-- (hb : TopologicalSpace.IsTopologicalBasis b)
--  : IsOpen s ↔ ∀ (a : α), a ∈ s → ∃ t, t ∈ b ∧ a ∈ t ∧ t ⊆ s


set_option maxHeartbeats 0 in
theorem monotone_of_upper_lower_continuous
    (f : ℝ → ℝ)
    (huc : Continuous[tᵤ, tᵤ] f)
    (hlc : Continuous[tₗ, tₗ] f)
    : Monotone f := by
/- Paper proof:
    Consider the disjoint sets

    A = (-∞, f(z))
    B = [f(z), ∞)

    We show by real induction that [z, ∞) ⊆ f⁻¹(B).

    We must show
     (L1) ∀x ∈ f⁻¹(B). ∃y. [x,y) ⊆ f⁻¹(B)
    Follows because f is an L-map.

     (L2) ∀xy. [x, y) ⊆ f⁻¹(B) ⇒ y ∈ f⁻¹(B)

    Assume towards a contradiction that y ∉ f⁻¹(B), therefore y ∈ f⁻¹(A).
    Since f is an R-map, there is an open interval (y-ε,y] such that
    f(y-ε,y] ⊆ A. But we have by assumption that f[x,y) ⊆ B, and
    y-ε/2 ∈ [x,y) ∩ (y-ε,y], so we have f(y-ε/2) ∈ A but also f(y-ε/2) ∈ B, a contradiction.
-/
  intro z b hz
  let A := (Set.Iio (f z))
  let B := Set.Ici (f z)

  have L1 : ∀ (x : ℝ), x ∈ f ⁻¹' Set.Ici (f z) → ∃ y, x < y ∧ Set.Ico x y ⊆ f ⁻¹' Set.Ici (f z) := by
    intro x hx
    have inverse_image_open : IsOpen[tₗ] (f ⁻¹' Set.Ici (f z)) := by
      apply @IsOpen.preimage ℝ ℝ tₗ tₗ f hlc (Set.Ici (f z))
      exact infinite_interval_lower_open (f z)
    have h2 := (@TopologicalSpace.IsTopologicalBasis.isOpen_iff ℝ tₗ (f ⁻¹' (Set.Ici (f z)))
       lower_intervals lower_basis).mp inverse_image_open x hx
    obtain ⟨ t , ht, xint, tsub ⟩ := h2
    obtain ⟨ ta, ⟨ tb, htb ⟩⟩ := ht
    use tb
    constructor
    · rw [←htb] at xint
      exact xint.2
    · have auxsub : Set.Ico x tb ⊆ t := by
        intro xx hxx
        rw[←htb]
        rw[←htb] at xint
        constructor
        · exact xint.1.trans hxx.1
        · exact hxx.2
      exact auxsub.trans tsub

  have L2 : ∀ (x : ℝ), x ∈ f ⁻¹' Set.Ici (f z) →
            ∀ (y : ℝ), x < y →
            Set.Ico x y ⊆ f ⁻¹' Set.Ici (f z) →
            y ∈ f ⁻¹' Set.Ici (f z) := by
    -- A = (-∞, f(z))
    -- B = [f(z), ∞)
    -- Assume towards a contradiction that y ∉ f⁻¹(B), therefore y ∈ f⁻¹(A).
    intros x hx
    by_contra' H
    obtain ⟨y, hxy, hxyz, hy⟩ :=  H

    -- A is open in tᵤ
    have h1 := infinite_interval_upper_open (f z)

    -- Since f is tᵤ-continuous, `f ⁻¹' A` is open
    have h2 := @IsOpen.preimage _ _ tᵤ tᵤ f huc (Set.Iio (f z)) h1

    -- Then there is an tᵤ-open interval ii such that
    -- f '' ii ⊆ A.

    have h3 : y ∈ f ⁻¹' Set.Iio (f z) := by aesop
    have h4 := (@TopologicalSpace.IsTopologicalBasis.isOpen_iff
                 ℝ tᵤ _ upper_intervals upper_basis).mp h2 y h3
    obtain ⟨ii, ⟨ii0, ii1, hiiu'⟩, hyii, hiis⟩ := h4

    have h5 : Set.Ioc ii0 y ⊆ f ⁻¹' Set.Iio (f z) := by
      have h999 : Set.Ioc ii0 y ⊆ Set.Ioc ii0 ii1 := by
          intros w hw
          constructor
          · aesop
          · rw[← hiiu'] at hyii
            cases' hyii with hyiil hyiir
            cases' hw with hwl hwr
            linarith
      rw [hiiu'] at h999
      exact h999.trans hiis

    let ii0' := max ii0 x

    let m := (ii0' + y) / 2
    -- But we have by assumption that f[x,y) ⊆ B, (hxyz)
    -- and m ∈ [x,y) ∩ (ii0, y]
    have h6 : m ∈ Set.Ico x y := by
      constructor
      · have h10 : x ≤ ii0' := by aesop
        have h11 : x + x < y + ii0' := add_lt_add_of_lt_of_le hxy h10
        have h13 : (x + x) / 2 < (y + ii0') / 2 :=
          div_lt_div_of_lt two_pos h11
        rw[←two_mul, show 2 * x / 2 = x by ring, add_comm] at h13
        exact le_of_lt h13
      · have h14 : ii0' < y := by aesop
        have h15 : y + ii0' < y + y := Iff.mpr (Real.add_lt_add_iff_left y) h14
        have h16 : (y + ii0') / 2 < (y + y) / 2 := div_lt_div_of_lt two_pos h15
        rw[←two_mul, show 2 * y / 2 = y by ring, add_comm] at h16
        exact h16

    have h7 : m ∈ Set.Ioc ii0' y := by
      cases' h6 with h6l h6r
      constructor
      · have h17 : ii0' < y := by aesop
        have h18 : ii0' + ii0' < y + ii0' := add_lt_add_right h17 ii0'
        have h19 : (ii0' + ii0')/2 < (y + ii0')/2 := div_lt_div_of_lt two_pos h18
        rw[←two_mul, show 2 * ii0' / 2 = ii0' by ring, add_comm] at h19
        exact h19
      · exact le_of_lt h6r

    -- so we have f(m) ∈ A
    have h8 : f m ∈ Set.Iio (f z) := by aesop

    -- but also f(m) ∈ B, a contradiction.
    have h9 : f m ∈ Set.Ici (f z) := by aesop

    rw[Set.mem_Iio] at h8
    rw[Set.mem_Ici] at h9
    linarith

  have h0 : Set.Ici z ⊆ f ⁻¹' (Set.Ici (f z)) :=
    real_induction L1 L2 (@Set.left_mem_Ici _ _ (f z))
  aesop

theorem properties_of_upper_lower_continuous
    (f : ℝ → ℝ)
    (huc : Continuous[tᵤ, tᵤ] f)
    (hlc : Continuous[tₗ, tₗ] f)
    : Continuous[tₛ, tₛ] f ∧ Monotone f := by
  constructor
  · exact continuous_of_upper_lower_continuous f huc hlc
  · exact monotone_of_upper_lower_continuous f huc hlc
