# Hyperboliq Assessment

Hyperboliq Assesment - An application that Splits an uploaded image up into segments and replaces them with "Tiles" stored within the assets folder. The application iterates through each image segment and compares it against each stored asset, to determine closest Delta E* CIE. Each image segment is then replaced with the corresponding asset tile, and the resulting image is a collage of assets. Due to the Delta E* CIE comparison, the collage will look relatively similar to the originial image at a glance, or at distance. 

## Notes
Sorry for the spaghetti code at some points, I was up quite late trying to get this out. After some initial tests, the application seems to perform its function, albeit slowly. I'm sure it could definitely be faster with more efficient looping algorithms, particularly when iterating through the thousands of assets. After uploading the image, it takes about a minute and a half to generate the "Tiled collage".
