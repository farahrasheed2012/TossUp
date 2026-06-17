# TossUp topic IDs for Claude question generation

Add questions to bundled JSON with `"topicId": "<id below>"`.  
File format matches `hewitt_ch17_questions.json` (see `BundledQuestionLoader.swift`).

## Chemistry (`subject`: `"chemistry"`)

| topicId | Topic name |
|---------|------------|
| `chem-all` | All Chemistry (auto-includes PDFs + bundles) |
| `chem-elements-of-chemistry` | Elements of Chemistry — Hewitt Ch 17 (full chapter) |
| `chem-elements-17-1` | §17.1 Chemistry Is Known as the Central Science |
| `chem-elements-17-2` | §17.2 The Submicroscopic World Is Super-Small |
| `chem-elements-17-3` | §17.3 The Phase of Matter Can Change |
| `chem-elements-17-4` | §17.4 Matter Has Physical and Chemical Properties |
| `chem-elements-17-5` | §17.5 Determining Physical and Chemical Changes |
| `chem-elements-17-6` | §17.6 The Periodic Table |
| `chem-elements-17-7` | §17.7 Elements Can Combine to Form Compounds |
| `chem-elements-17-8` | §17.8 There Is a System for Naming Compounds |
| `chem-atoms-periodic-table` | Atoms & Periodic Table |
| `chem-bonding` | Chemical Bonding |
| `chem-reactions` | Chemical Reactions |
| `chem-solutions-acids` | Solutions & Acids/Bases |
| `chem-stoichiometry` | Stoichiometry & Moles |
| `chem-states-of-matter` | States of Matter |
| `chem-lab-measurement` | Lab & Measurement |

## Biology (`subject`: `"biology"`)

| topicId | Topic name |
|---------|------------|
| `bio-all` | All Biology |
| `bio-cells` | Cell Structure & Organelles |
| `bio-energy` | Photosynthesis & Cellular Respiration |
| `bio-genetics` | DNA, Genes & Chromosomes |
| `bio-inheritance` | Punnett Squares & Inheritance |
| `bio-evolution` | Evolution & Classification |
| `bio-ecology` | Ecology & Ecosystems |
| `bio-body-systems` | Human Body Systems |
| `bio-microbes` | Bacteria, Viruses & Disease |

## Math (`subject`: `"math"`)

| topicId | Topic name |
|---------|------------|
| `math-all` | All Math |
| `math-number-sense` | Number Sense & PEMDAS |
| `math-fractions-percent` | Fractions, Decimals & Percent |
| `math-ratios-proportions` | Ratios & Proportions |
| `math-exponents-sci-notation` | Exponents & Scientific Notation |
| `math-linear-equations` | Linear Equations & Word Problems |
| `math-graphs-slope` | Graphs, Slope & Functions |
| `math-probability-stats` | Probability & Statistics |
| `math-radicals` | Square Roots & Radicals |

## Example JSON record

```json
{
  "id": "bio-cells-001",
  "subject": "biology",
  "topicId": "bio-cells",
  "round": "Toss-Up",
  "type": "multipleChoice",
  "questionText": "Which organelle is the primary site of ATP production in eukaryotic cells?",
  "choices": ["W) Nucleus", "X) Mitochondrion", "Y) Ribosome", "Z) Golgi apparatus"],
  "correctAnswer": "X",
  "sourcePDF": "Bundled-Bio"
}
```

Hewitt Ch 17 questions infer `topicId` from `§17.x` in `round` when `topicId` is omitted.

## Claude prompt starter

> Write 20 middle-school National Science Bowl toss-up questions for topic **bio-cells** (Cell Structure & Organelles). Mix multiple choice (W/X/Y/Z) and short answer. Return JSON array matching the example above with `topicId` set on every row.
