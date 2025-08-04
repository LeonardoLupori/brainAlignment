# Image acquisition

## Naming convention

The convention for naming files contains:

- **Mouse ID**  
A 4 digits/characters string with an unique identifier of the mouse to which the slice belong.  
Examples: `CC1A`, `0014`, `AACB`
- **Slice Absolute number**  
As the brain is cut, the slice number `001` is the first slice cut, while the slice number `070` is the 70th slice cut. It is important to use a 3 digits numbers with **leading zeros**. Please note that in your dataset you will most likely not acquire every slice in the brain so you will end up with a non continuos numbering (e.g., 001, 004, 007,...). This is desirable, as keeping trace of the absolute slice number at the moment of brain cutting also gives an approximate idea of the distance between two slices.
- **Immuno well name**  
A 2-characters code of the name of the well where the IHC reaction of this slice was performed. This is useful if you want to troubleshoot possible errors due to the IHC reaction not working properly in one of the wells.  
Examples: `A1`, `D4`, `C6`
- **Subslice number**  
A 1-digit number. Sometimes a slice split into multiple parts (e.g., the most posterior parts of the cortex are not held in place by the corpus callosum anymore and, when cut, separate from the central part of the brain). The best procedure for the pipeline is to mount these slices parts on the microscopy slides as if they were individual slices and acquire separate images. Each one has the same slice absolute number but is assigned a different subslice number.  

- (optional) **File descriptor**  
Inside the dataset, a single slice will have several accompanying files (e.g., a mask, a cell count...). These files take the name of the slice, but have a trailing file descriptor defined with a dash `-` and a name.  
Possible descriptors are:
    - `-mask`
    - `-cells`
    - `dispFieldX`
    - `dispFieldY`
    - `thumb`

- (optional) **Channel name**  
For files that refers to a single channel (e.g., hiRes images and cell counts) the file name has a trailing 2-character string defining which channel they refer to.  
For example, `_C1` refers to channel 1 (usually red), `_C2` refers to channel 2 etc.

These elements are arranged in this specific way:

`MOUSEID_001_C1-descriptor_C2.extension`

Here are some examples of valid filenames for a mouse named `TESTMOUSE`

- `TESTMOUSE_013_A1-cells_C1.csv`

  File with the cell counts relative to the first channel of the slice #13 of the mouse `TESTMOUSE`. The IHC reaction was performed in the well number A1

- `TESTMOUSE_095_A4-dispFieldX.csv`

  File with the displacement field on the X direction relative to the slice #95 of the mouse `TESTMOUSE`. The IHC reaction was performed in the well number A4

- `TESTMOUSE_015_D3-C2.tif`

  File with the high-resolution original image relative to channel #2 of the slice #95 of the mouse `TESTMOUSE`. The IHC reaction was performed in the well number D3

## Experimental requirements

### Coronal slices

Images need to be *coronal* whole sections of the mouse brain acquired by means of either a tiling procedure of multiple high-magnification images, or a large field-of-view objective.

### Correct orientation

In order to minimize subsequent post-processing steps it's ideal to acquire images with the correct dorsoventral orientation and with minimal tilt.

### Same acquisition parameters

Images belonging to the same experiment have to be acquired with the same acquisition parameters (e.g., illumination/LASER intensity, exposure time, objective), in order for the intensity values to be comparable.

## Export images

Images should be exported from ZEN blue lite in `.tif` format with an 8-bit bit-depth. Compression algorithms are fine as long as a lossless one is used (e.g., [LZW](https://en.wikipedia.org/wiki/Lempel%E2%80%93Ziv%E2%80%93Welch)).  
If the image is a **multichannel** image, export an RGB version, as long as each channel is in a separate color.

[next ➡](02_filesPreparation.md)

---

*Leonardo Lupori and Valentino Totaro*
