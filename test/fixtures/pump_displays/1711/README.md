# Pump-display OCR failure corpus — #1711

Ten real fuel-pump photos (downsized to ≤1280 px) on which the
**"Ajouter un plein" → pump-display scan** failed — it detected neither
the litres nor the price. Captured by the reporter, 2026-05-15, French
market (Tokheim + Wayne pumps).

These are the OCR regression corpus for #1711: the fix must extract the
three transaction numbers from these, and a regression test should pin
that.

## The corpus

| File | Pump display reads | Capture problem |
|------|--------------------|-----------------|
| `pump_9690.jpg` | PRIX 24,94 € · VOLUME 29,3x L · P/L 0,849 | **Upright**, but heavy glass glare (trees/cars reflected over the digits) |
| `pump_9548.jpg` | PRIX 8,03 · VOLUME 8,93 · P/L 0,899 | **Rotated 90°** — the PRIX/VOLUME labels run vertically |
| `pump_9549.jpg` | PRIX 8,03 · VOLUME 8,93 · P/L 0,899 | Rotated 90°, **wide shot** — display is a small part of the frame |
| `pump_9550.jpg` | PRIX 10,00 · VOLUME 11,12 · P/L 0,899 | Rotated 90°, wide shot |
| `pump_9518.jpg` | PRIX ~30,8x · VOLUME ~15,5x · P/L 1,990 | Rotated 90°, **extreme washout** — sky reflection bleaches the LCD |
| `pump_9519.jpg` | PRIX 79,9x · VOLUME 36,06 · P/L 2,3x6 | Rotated 90°, glare |
| `pump_9499.jpg` | PRIX 10,47 · VOLUME 5,24 · P/L 1,999 | Rotated 90°, low-contrast grey-on-grey LCD |
| `pump_9497.jpg` | PRIX 40,04 · VOLUME 20,03 · P/L 1,999 | Rotated 90°, wide shot |
| `pump_9498.jpg` | PRIX 30,02 · VOLUME 13,4x · P/L 2,235 | Rotated 90°, cracked/dirty display glass |
| `pump_9496.jpg` | PRIX ~?? · VOLUME ?? · P/L 1,8x | Rotated 90°, washed-out white Wayne LCD |

(`x` = a digit even a human can't read off the photo — that is itself a
finding: the capture quality is the limiting factor.)

## Root-cause analysis

The scan flow is `_capture()` → `InputImage.fromFilePath(path)` →
ML Kit `TextRecognizer.processImage` → `PumpDisplayParser.parse` in
`lib/features/consumption/data/receipt_scan_service.dart`.

1. **Orientation is lost (primary cause).** `InputImage.fromFilePath`
   hands the raw bitmap to ML Kit **without applying the JPEG's EXIF
   `Orientation` tag**. 9 of the 10 photos are stored sideways (the
   display reads at 90°). ML Kit's Latin `TextRecognizer` reads roughly
   upright text — sideways 7-segment digits are not detected or come
   back as garbage, so the parser receives nothing usable.
2. **7-segment LCD font.** Even the one upright photo (`pump_9690`) uses
   segmented digits with gaps between segments. ML Kit's general
   recognizer is trained on continuous typefaces and is unreliable on
   7-segment displays — it drops digits or misreads them. The parser's
   7-segment confusion normalisation only helps once OCR returns text.
3. **Glare & reflections.** The displays sit behind glass; reflected
   trees, cars, sky and the photographer overlap the digits
   (`pump_9690`, `pump_9518`, `pump_9519`).
4. **Wide framing → pollution.** The one-shot camera pick has no framing
   guide, so several shots capture the whole pump: metrology sticker,
   `TOKHEIM`/`Wayne` logos, the bold pump number (`1`–`4`), and
   card-reader text (`CB`, `CARTE`, `PRÉPAIEMENT`, `Vmin = 5L`, …). The
   parser then has to find three numbers in a sea of text.
5. **Low contrast / washout.** Grey-on-grey LCDs and sky-bleached
   displays; no contrast/threshold preprocessing before OCR.

## Suggested fix direction

- **Orientation:** bake the EXIF rotation into the bitmap before OCR, or
  retry OCR at 0°/90°/180°/270° and keep the rotation whose parse has
  the highest confidence.
- **Capture guide:** an on-screen framing reticle so the user fills the
  frame with just the three-number display.
- **Preprocessing:** a contrast/threshold pass to help the 7-segment +
  washout cases.
