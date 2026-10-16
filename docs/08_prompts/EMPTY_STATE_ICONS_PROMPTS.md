# Empty-state illustrations — prompts

Spot illustrations for empty screens (Guild Hall Allies / Scrolls / Duels, Shop category, Arena Revenge), replacing SF Symbols (`person.2.slash`, `scroll.fill`, `figure.fencing`, `cart`, `shield`). Generated 2026-10-16.

- Family: pen-and-ink rulebook (`ART_STYLE_GUIDE.md` template verbatim + fixed light sentence), magenta key `#FF00FF`.
- Model: `nano_banana_2_1`, 1:1, 2k, thinking medium. Anchor: `Items/chest_godplate` = `1c5bda93-1f54-4c55-9261-c03d3d8fe087` (`image_references`).
- Ingest: `scripts/ingest_generated_sprite.py <raw> <name> --pt 180 --key FF00FF --out Hexbound/Hexbound/Resources/Assets.xcassets/EmptyStates` → @3x ≈ 540 px, display up to ~180 pt.
- Every prompt starts with the anchor sentence: *"Image 1 is the STYLE ANCHOR from the same icon set: match its pen-and-ink linework, outline weight, lighting and colouring exactly; do not copy its subject."* and ends with the class tail: *"a single spot illustration for an empty screen, big clear shapes that read at 96 points, the subject filling about 75% of the frame,"* + the template's light / isolation / negative clauses + *"The ENTIRE background is one flat, uniform, solid bright magenta colour (#FF00FF) edge to edge, no pattern, no stripes, no frame, no border."*

| Asset | Subject (between "Pen and ink illustration of" and the tail) | Job |
|---|---|---|
| `empty-allies` | two armoured knight gauntlets clasped together in a firm warrior's forearm grip, seen from the side, one gauntlet of dark blued steel and one of worn iron with bronze trim, a frayed crimson cloth ribbon knotted around the joined wrists, rivets, scratches and small dents on the plates — gunmetal steel grey and warm bronze tones, deep crimson (#9E2B25) accents | `e5932ba0-9f31-4a39-9291-415909cde619` |
| `empty-scrolls` | a rolled-up letter scroll lying at a gentle diagonal, tied with a twisted hemp cord and closed with a round wax seal stamped with a simple hexagon shape, a long dark feather writing quill resting across the scroll, the paper ends gently curled — aged bone and tan paper tones with brown ink shading, deep burgundy wax accents | `b0d6d205-ae83-4172-901d-610c0753ef84` |
| `empty-duels` | a single knight's armoured glove resting palm-down on a square stone floor tile, fingers slightly spread, the flared cuff edged with worn gold trim, the classic gesture of inviting someone to a friendly contest — gunmetal steel grey and slate stone tones, tarnished gold (#D4A537) accents | `2bb3089c-2ce6-4a02-bd3d-640de888e156` |
| `empty-shop` | an open, empty wooden merchant's chest seen from a three-quarter view, iron-banded oak planks, the heavy lid propped wide open, nothing inside but a few loose straw stalks and one thin cobweb strand in the inner corner, a small iron padlock hanging open from the hasp — dark oak brown and blackened iron tones, tarnished gold (#D4A537) rivet accents | `cf817f45-6596-4b14-9698-19241739f576` |
| `empty-revenge` | a round wooden shield hanging on an iron wall hook, clean and unmarked, a domed iron boss in the centre, oak planks bound by an iron rim, a faded burgundy painted band across the face — weathered oak brown and dark iron tones, deep burgundy accents | `aaf5f83b-6557-465d-9420-1e5dfdd37364` |

Defect ledger: first submission of scrolls / thrown gauntlet / shield-with-sword came back as false NSFW flags ("crimson", "thrown down", "sheathed short sword", "torn"); reworded as above, all accepted on the first re-roll. Scrolls ingest: 86 px key residue (0.01%), invisible at display size.
