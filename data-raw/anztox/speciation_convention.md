# Arsenic Speciation Convention Decision (ANZECC / ANZG)

## ✅ Recommended Decision

**Resolve arsenite, arsenate, and other arsenic oxyanions to the elemental analyte ‘Arsenic’ (total or dissolved), rather than keeping them as separate ions — unless explicitly performing speciation-based assessment.**

---

## Rationale

### 1. Guideline values are defined for arsenic as a single toxicant
- ANZECC/ANZG guidelines treat arsenic as a **single chemical entity** for water quality assessment.
- Guideline comparisons are typically made against **total arsenic concentrations**.
- Analytical reporting commonly references **total arsenic (µg/L)**.

**Implication:** Reporting should align with the elemental form (“Arsenic”), not individual oxyanions.

---

### 2. Speciation is scientifically important but secondary
- Arsenic occurs primarily as:
  - **As(III) (arsenite)**
  - **As(V) (arsenate)**
- Toxicity varies by form (As(III) generally more toxic).
- However, speciation is typically used in **advanced risk assessment or bioavailability studies**, not routine compliance.

**Implication:** Speciation can be retained as metadata, but not as the primary reporting unit.

---

### 3. Distinction from nutrient ions

| Group | Recommended handling | Reason |
|------|--------------------|-------|
| Metals / metalloids (e.g. arsenic) | Collapse to element | Guidelines apply to total element |
| Nutrients (e.g. nitrate, nitrite, phosphate) | Keep as ions | Each species has distinct ecological roles and guideline values |

**Implication:** Your current model split (metals vs nutrients) is consistent with guideline intent.

---

## Practical Rule for Data Processing

### ✅ Apply this mapping
- Arsenite (As III) → Arsenic
- Arsenate (As V) → Arsenic
- Arsenic acid → Arsenic
- Dissolved arsenic → Arsenic

### ❌ Do NOT treat arsenite like nitrate
- Do not preserve arsenite/arsenate as standalone analytes for routine guideline comparison.

---

## Optional Best-Practice Schema

To retain useful detail while staying compliant:

- **Primary field:** `Analyte = Arsenic`
- **Secondary field (optional):** `Speciation = As(III) / As(V) / Unknown`

This allows:
- Clean guideline comparison
- Retention of speciation detail
- Flexibility for advanced analyses

---

## Bottom Line

- Collapse arsenic oxyanions to **“Arsenic”** for main analysis.
- Maintain speciation only as **supplementary information** if needed.
- This aligns with ANZECC/ANZG guideline structure and avoids inconsistencies in large batch processing.

---

## Resolution Precedence Rules

When a compound could map to more than one analyte (e.g. a trace metal
sulfate could resolve to either the metal or sulfate), apply the
following precedence order:

1. Trace metals and metalloids (highest priority) → resolve to element
2. Nutrient ions (nitrate, nitrite, phosphate, sulfate, halides) →
   resolve to ion
3. Major ions / background chemistry (Ca, Mg, Na, K) → resolve to
   associated anion where applicable

This means a compound such as ZnSO4 resolves to Zinc (not Sulfate),
and NaCl resolves to Chloride (not Sodium).

Full policy decisions and rationale are documented in
`scripts/speciation_policy_extensions.md` (D1-D4, agreed 2026-06-23).

Strontium is classified as a trace metal (resolves to element),
consistent with Barium and distinct from Calcium/Magnesium. See D3.
