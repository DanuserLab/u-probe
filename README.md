# u-probe 3.7
<a class="twitter-share-button"
   href="https://twitter.com/intent/tweet?text=🚀 Check out @DanuserLab's u-probe software package on GitHub: https://github.com/danuserlab/u-probe"
   data-size="large">
  Share on X
</a>

![Alt Text](img/biosensorpkg.jpg?raw=true)

## Introduction
This MATLAB software package allows processing of raw ratiometric biosensor images (for example based on FRET) into fully corrected "ratio maps" or "activation maps" — images showing the localized activation of the biosensor. This includes application of all necessary image corrections needed for quantitative widefield imaging of ratiometric biosensors.

For more information, please see [**Biosensors for characterizing the dynamics of rho family GTPases in living cells**](https://www.ncbi.nlm.nih.gov/pubmed/20235099), *Curr Protoc Cell Biol*, 2010, Chapter 14:Unit 14.11.1-26, written by Louis Hodgson, Feimo Shen, Klaus Hahn.

## Documentation
Detailed instructions for how to download and load the u-probe package into MATLAB is provided via the [Wiki](https://github.com/DanuserLab/u-probe/wiki/Installation) tab that is located at the top of this GitHub repository.

Comprehensive descriptions of the u-probe package and its individual steps are available on the [Wiki](https://github.com/DanuserLab/u-probe/wiki/u-probe-Package-Description) tab as well.

## Software Feedback
Please submit any feedback on this package, including bugs and feature requests, via the [Issues](https://github.com/DanuserLab/u-probe/issues) tab that is located at the top of this GitHub repository. General instruction on how to create an issue on GitHub can be found [here](https://docs.github.com/en/issues/tracking-your-work-with-issues/creating-an-issue).

## Version History
### New in Version 3.7 (April, 2025):
- Updated Step 12 Ratio Output to allow manual specification of color scale limits for the ratio output images.

### New in Version 3.6 (Jan. 16th, 2025):
- Improved the MSA (Multi Scale Automatic) Segmentation Process. Added a "Preview segmented image" option, and options to turn the display output figures or verbose mode on or off during the execution.

### New in Version 3.5 (Dec. 5th, 2024):
- Improved the External Segmentation Process. Now accept both single TIFF images and image stacks as external masks.
  
### New in Version 3.4 (Nov. 8th, 2024):
- Improved the Bleedthrough Correction Process
- Bug fixed in Bleedthrough Coefficient Calculation tool
  
### New in Version 3.3 (Oct. 9th, 2024):
- Updated Step 12 Ratio Output to export 32-bit TIFs without a scale factor. Other improvements enhance user experience and robustness.
  
### New in Version 3.2:
- Renamed the software package from **Biosensor** to **u-probe**. Please select **u-probe** from the analysis packages list to run the software.

### New in Version 3.1:
- Added a step to crop a ROI for segementation and its following steps.

### New in Version 2.1:
- Added support for movie relocation
- Implemented a graphical interface for preparing data
- Added a preview option when manually thresholding channels
- Added graphical interfaces for the transformation creation and bleedthrough coefficients calculation
- Included the ratio movie creation within the output process
- Fixed various bugs (correction image display...)

## Running u-probe Without a MATLAB License
u-probe 3.7 is now available as a standalone application.
> Note: You must install MATLAB Runtime to run the standalone application. No MATLAB license is required.
### For Windows, compiled with MATLAB Runtime R2024b.
- [Download u-probe 3.7 Standalone](https://cloud.biohpc.swmed.edu/index.php/s/SMyqd5sxPBLQNtH) and [Install MATLAB Runtime R2024b (Windows)](https://www.mathworks.com/products/compiler/matlab-runtime.html)
### For Linux, compiled with MATLAB Runtime R2024a.
- [Download u-probe 3.7 Standalone](https://cloud.biohpc.swmed.edu/index.php/s/nNFdHEFdw2aAoXr) and [Install MATLAB Runtime R2024a (Linux)](https://www.mathworks.com/products/compiler/matlab-runtime.html)
  
## Danuser Lab Links
[Danuser Lab Website](https://www.danuserlab-utsw.org/)

[Software Links](https://github.com/DanuserLab/)
