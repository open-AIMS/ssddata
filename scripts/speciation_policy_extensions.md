# Speciation Policy Decisions (Halides, Alkaline Earths, and Trace Metals)

## Purpose

This document formalises several policy decisions regarding how compounds are resolved to analytes within the ANZG-aligned speciation framework. These decisions extend and clarify the existing convention distinguishing:

- **Trace metals / metalloids → resolve to element**
- **Nutrients / major ions → resolve to ion**

as established in the arsenic speciation rule (see `data-raw/anztox/speciation_convention.md`)

---

## D1 — Alkali-Metal Halides

### Decision
**Alkali-metal halides (e.g., NaCl, KBr) SHALL resolve to the halide ion (e.g., Chloride, Bromide), not the metal.**

### Rationale

1. **Guideline alignment**
   - ANZG guidelines are defined for **halide ions (e.g., chloride)** rather than sodium or potassium individually.
   - Sodium and potassium are typically not treated as primary toxicants.

2. **Chemical behaviour**
   - Halides are:
     - Conservative in aquatic systems
     - The ecologically relevant species
   - Alkali metals (Na⁺, K⁺) function primarily as **salinity contributors**, not pollutants in their own right.

3. **Framework consistency**
   - Halides fall under the **“retain as ions”** category (like nitrate, phosphate) (see `data-raw/anztox/speciation_convention.md`).

### Examples

| Compound | Resolved analyte |
|----------|------------------|
| NaCl     | Chloride         |
| KCl      | Chloride         |
| NaBr     | Bromide          |

### Recommendation
✅ Maintain current handling  
✅ No changes required  

---

## D2 — Barium vs Calcium/Magnesium Split

### Decision
**The asymmetry is intentional and SHOULD be preserved:**
- **Barium → resolve to element**
- **Calcium / Magnesium → resolve to associated anion**

### Rationale

1. **Toxicological classification**
   - **Barium**:
     - Trace metal
     - Has element-level toxicity and guideline relevance
   - **Calcium / Magnesium**:
     - Major ions
     - Ecologically important but not treated as toxicants at typical concentrations

2. **Guideline structure**
   - Trace metals are assessed as **elements**
   - Major ions are typically considered:
     - Collectively (e.g., hardness)
     - Or via associated anions (e.g., sulfate)

3. **Conceptual consistency**
   - Barium aligns with:
     - Lead (Pb)
     - Copper (Cu)
     - Zinc (Zn)

   - Calcium and magnesium align with:
     - Background water chemistry
     - System-level modifiers rather than contaminants

### Recommendation

✅ Retain asymmetry  
✅ Explicitly document it as **intentional**, not incidental  

---

## D3 — Strontium Treatment

### Decision
**Strontium SHALL be treated as a trace metal analogue and resolve to the element (Strontium).**

### Rationale

1. **Regulatory behaviour**
   - Strontium is not treated as a nutrient or major ion
   - When considered, it is **evaluated at the element level**

2. **Chemical vs policy classification**
   - Although chemically similar to Ca/Mg, policy frameworks treat it differently:
     - It does **not contribute meaningfully to hardness frameworks**
     - It is not managed as a bulk ion

3. **Consistency with trace metal handling**
   - Treating Sr like Ca/Mg creates inconsistency
   - Aligning Sr with Ba ensures:
     - Predictable handling
     - Cleaner rule application

### Change Required

| Current behaviour | Updated behaviour |
|------------------|------------------|
| Sr compounds → anion | Sr compounds → **Strontium (element)** |

### Recommendation

✅ Update mapping for all strontium-containing compounds  
✅ Group Sr with trace metals in logic layer  

---

## D4 — Trace Metal Precedence Rule

### Decision
**The “trace metal overrides nutrient anion” rule SHALL be formally documented.**

### Rule Definition

When a compound contains:
- a **trace metal** (e.g., Ba, Sr, Zn, Cu, Pb), and
- a **common anion** (e.g., chloride, sulfate, carbonate),

→ the analyte **must resolve to the trace metal (element)**.

### Rationale

1. **Guideline primacy**
   - Toxicity and regulatory thresholds are defined for the **metal**, not the paired anion

2. **Avoiding ambiguity**
   - Without this rule, compounds such as:
     - ZnSO₄
     - CuCl₂
     - BaCO₃
   could be inconsistently resolved

3. **Consistency with existing framework**
   - This rule is already implicitly applied via:
     - “Metals → element”
     - “Nutrients → ions” 【1-2603c7】

   - Formalising it prevents future drift

### Examples

| Compound | Resolved analyte |
|----------|------------------|
| BaCl₂    | Barium           |
| ZnSO₄    | Zinc             |
| SrCO₃    | Strontium        |

### Recommendation

✅ Add rule to `speciation_convention.md`  
✅ Place under a new section: **“Resolution Precedence Rules”**  

---

## Summary of Decisions

| Decision | Outcome |
|----------|--------|
| D1 — Alkali halides | Resolve to halide ion |
| D2 — Ba vs Ca/Mg | Asymmetry preserved |
| D3 — Strontium | Treat as element (like Ba) |
| D4 — Override rule | Document explicitly |

---

## Overall Recommendations

1. **Codify rules, not just examples**
   - Transition from case-by-case handling to **rule-driven resolution**

2. **Introduce a precedence hierarchy**
   Suggested order:

   1. Trace metals (highest priority)
   2. Metalloids
   3. Nutrient ions
   4. Major ions / background chemistry

3. **Preserve speciation as metadata**
   - Continue best practice established for arsenic:
     - Primary analyte = element or ion
     - Speciation retained as secondary field (see `data-raw/anztox/speciation_convention.md`)

4. **Audit edge cases**
   - Particularly:
     - Mixed-metal salts
     - Rare earths / alkaline earth edge cases
     - Organometallics (future consideration)

---

## Bottom Line

These decisions:
- Reinforce internal consistency
- Align with ANZG guideline structure
- Reduce ambiguity for automated processing
- Provide a scalable foundation for future extensions
