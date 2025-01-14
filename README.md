# brainageR_dockerfile

Dockerfile creates a base docker container that can execute the new version 2.1 of brainageR (author James Cole) which can be found on https://github.com/james-cole/brainageR. BrainageR is software for generating a brain-predicted age value from a raw T1-weighted MRI scan.

You can analyze a raw T1-weighted MRI scan with the following command:

       docker run --rm -it -v ${PWD}/your_data:/data -w /data psadil/brainager -f /data/sub-01_T1w_defaced.nii -o /data/subj01_brain_predicted.age.csv

'sub-01_T1w_defaced.nii' is the name of the raw T1-weighted MRI scan decompressed in nii format placed in your_data folder, and 'subj01_brain_predicted.age.csv' is the .csv file where the age predictions are saved.
