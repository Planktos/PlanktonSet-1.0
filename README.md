# PlanktonSet-1.0
Data sets and 'R' scripts used to create competition data for the 2015 National Data Science Bowl, sponsored by Kaggle and Booz Allen Hamilton with data provided by OSU's Hatfield Marine Science Center.

Cite as: Cowen, Robert K.; Sponaugle, Su; Robinson, Kelly L.; Luo, Jessica; Guigand, Cedric (2015). PlanktonSet 1.0: Plankton imagery data collected from F.G. Walton Smith in Straits of Florida from 2014-06-03 to 2014-06-06 and used in the 2015 National Data Science Bowl (NODC Accession 0127422). National Oceanographic Data Center, NOAA. Dataset. [access date]

For data set metadata: http://data.nodc.noaa.gov/cgi-bin/iso?id=gov.noaa.nodc:0127422

Techincal Notes
1. All images in the file “FINAL_Plankton_Segments_12082014” were scrubbed of existing metadata.

2. Dataset was then split into 50% train, and 50% test. These splits were done agnostic of the class identification.

3. 100,000 “poison" images were generated and added to the test set. These “poison” images supplemented the original dataset and were ignored during scoring; this was done to discourage manual classification of the test data. These images were generated using linear and non-linear transformations of the real test dataset (including adding noise, flipping, flopping, rotations, etc.)
Steps 2 and 3 can be replicated using the 'R' script “main.R”.

4. Images in the dataset were renamed.

5. For the competition, 30% of the test set were scored on the public leaderboard, while the rest of the test set scores were kept private on a separate (private) leaderboard. The rankings of the private leaderboard determined the final winners.
