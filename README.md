# u-probe 3.2
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
### New in Version 3.3 (October 9th, 2024)
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

## Danuser Lab Links
[Danuser Lab Website](https://www.danuserlab-utsw.org/)

[Software Links](https://github.com/DanuserLab/)
