# WazerDesktopFusion360PostProcessor
A Fusion 360 post processor for the Wazer Desktop water jet. It attempts to emulate some of the corner compensation found in Wazer's online WAM app by progressively slowing feedrate into corners and progressively speeding up out of them.

See Autodesk Support documents for instructions on how to install a post processor. This is a drop in replacement for Version 44191 of the wazer.cps post processor they have made available for the Wazer Desktop: https://cam.autodesk.com/posts/download.php?name=wazer&type=post

Some properties exposed to the user:

**Material:** A dropdown with prepopulated materials that have formulas defined for feedrates and pierce times. Each material has two corresponding feedrate formulas, one for rough cut quality and one for fine cut quality. A medium cut quality feedrate is the interpolation of the two.

**Maximum segment length for linear moves (mm):** This property governs how long G1 lines should be split into, which in turn governs how long the feedrate ramp down / ramp up schedule will be. WAM hardcodes a 5mm value for a similar property. Default value is 5mm.

**Minimum segment length for corner compensation (mm):** This property affects angle measurement by allowing the angle of a corner to be measured over vectors that are not necessarily adjacent to each other. This functionality was added to address the differences between how Fusion 360 and WAM generate gcode for corners. Default value is 0.4mm.

**Ignore Max thickness:** The wazer.cps post processor has a library of materials built in, each with a formula for their feed rate based on material thickness and desired surface finish. The Wazer Desktop has stated limits for thicknesses in their spec sheet and the post processor will throw an error if the material you are trying to cut exceeds the published max thickness for the machine. Checking this box allows you to bypass that max thickness check and proceed at your own risk. Default is unchecked.

**Include Fake Tool Select:** Checking this box inserts Txxx tool select calls allowing Fusion360-Batch-Post/PostProcessAll.py to be used. Default is unchecked. 
