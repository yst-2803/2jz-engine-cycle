# Toyota 2JZ Ideal Otto Cycle Model

Ideal Otto-cycle models of the naturally aspirated 2JZ-GE and the turbocharged 2JZ-GTE, written in GNU Octave. I wanted to see how close A-level thermodynamics and the Otto cycle get to a real engine's power, and whether they can predict what turbocharging adds.

## Result

| | Model | Real engine | Model ÷ real |
|---|---|---|---|
| 2JZ-GE power | 341.5 kW | 162 kW | 2.11 |
| 2JZ-GTE power | 533.6 kW | 239 kW | 2.23 |
| Gain from turbocharging (GTE ÷ GE) | 1.56× | 1.48× | 1.06 |

The model overpredicts absolute power about twofold, which is what an ideal cycle should do (see Limitations). It predicts the gain from turbocharging to within 6%, with nothing tuned to fit.

## Method

1. **Geometry.** Swept volume per cylinder from bore and stroke, clearance volume from the compression ratio.
2. **Charge.** The ideal gas equation at bottom dead centre gives the air mass. A stoichiometric air-fuel ratio of 14.7 gives the fuel mass, and the heat input is fuel mass × lower heating value (44 MJ/kg).
3. **Cycle.** Adiabatic compression ($pV^\gamma$ constant, $\gamma = 1.4$), heat added at constant volume, adiabatic expansion.
4. **Work.** The expansion and compression curves are integrated with the trapezium rule over 100 points. Net work per cycle is the difference.
5. **Power.** Net work × (rpm ÷ 120) × 6 cylinders, at the rated engine speed.
6. **Turbocharger (GTE only).** The compressor raises intake pressure by the stock boost. Its outlet temperature comes from an isentropic efficiency, and an intercooler effectiveness brings the charge back towards ambient. The cylinder then fills at that pressure and temperature.

## Inputs

| Parameter | Value | Source |
|---|---|---|
| Bore × stroke | 86.0 × 86.0 mm | engine-specs.net |
| Compression ratio | 10.0 (GE), 8.5 (GTE) | engine-specs.net |
| Rated power | 162 kW at 5800 rpm (GE), 239 kW at 5600 rpm (GTE) | engine-specs.net |
| Stock boost (GTE) | 0.8 bar gauge | autoevolution |
| Compressor isentropic efficiency | 0.7 | Assumed |
| Intercooler effectiveness | 0.7 | Assumed |
| Intake conditions | 101,325 Pa, 300 K | Assumed |

## Checks

| Check | Result |
|---|---|
| Displacement from bore and stroke vs nominal | 2.997 L vs 3.0 L |
| Net work by trapezium rule vs analytic Otto efficiency × heat input | 0.064% (GE), 0.046% (GTE) |
| Predicted gain with either assumed efficiency changed by 0.1 | 1.53× to 1.60× |
| Predicted gain with both changed by 0.1 together | 1.50× to 1.61× |

## The first version, and what was wrong with it

This is a rebuild. My first attempt was written in MATLAB; screenshots of the code and its output are in [`earlier_version/`](earlier_version/).

That version predicted 206 hp at the GTE's compression ratio, against a rated 320 hp (239 kW). An ideal cycle has no friction or heat loss, so it should predict more power than the real engine, not less. That told me the model was wrong before I knew where.

A line-by-line review found three errors:

1. **Cylinder volume.** `V1 = displacement / (compression_ratio - 1)` used the whole engine's 3.0 L displacement and the formula for clearance volume, and called the result the volume of one cylinder at bottom dead centre.
2. **Sign of the compression work.** The compression curve was integrated from large volume to small, so `trapz` returned a negative number. Subtracting it added the compression work to the net work.
3. **Combustion temperature.** `T3 = T2 * 3` assumed that combustion triples the temperature, when it should come from the heat released by the fuel.

The rebuilt model calculates the heat input from the air and fuel mass and is checked against the analytic Otto efficiency, as above.

## Limitations

- **It is an ideal cycle.** No heat loss, friction, pumping losses or finite combustion time, which is why absolute power comes out about double.
- **Constant $\gamma = 1.4$** for air throughout. The model's peak temperature is about 4,900 K, well above anything a real engine reaches.
- **The cylinder is assumed to fill completely** with a stoichiometric mixture at rated speed.
- **The turbocharger is represented only by its effect on intake pressure and temperature**, using assumed efficiencies. Exhaust back-pressure is ignored.

## Use of AI

I used an AI assistant to review the first version's code and locate the three errors listed above.

## Running it

Open the scripts in GNU Octave (written in 11.3) and run `naturally_aspirated.m`, then `turbocharged.m`. The turbo script compares against the naturally aspirated model's power and torque (341.5 kW, 562.2 Nm), which are entered as fixed values.

| File | Contents |
|---|---|
| `naturally_aspirated.m` | 2JZ-GE model |
| `turbocharged.m` | 2JZ-GTE model with turbocharger and intercooler |
| `earlier_version/` | Screenshots of the first MATLAB version and its output |
