import scmallet
from scmallet import Mallet, binarize_topics

#mallet = Mallet(output_dir="/fab/AlignedData/rsav_minimorf/paper_data/atac_cistopic/cistopics50/")
#num_topics = 50
#cell_topics = mallet.get_cell_topics(num_topics)
#region_topics = mallet.get_region_topics(num_topics)
#cell_topics.to_csv("/fab/AlignedData/rsav_minimorf/paper_data/atac_cistopic/out_matrices/celltopic50.txt", sep="\t")

for i in [5, 50, 75, 100, 125, 150, 175, 200]:
    # Define input/output paths for this number of topics
    mallet_output_dir = f"/fab/AlignedData/rsav_minimorf/paper_data/atac_cistopic/cistopics{i}/"
    output_file = f"/fab/AlignedData/rsav_minimorf/paper_data/atac_cistopic/out_matrices/celltopic{i}.txt"
    output_file2 = f"/fab/AlignedData/rsav_minimorf/paper_data/atac_cistopic/out_matrices/peaktopic{i}.txt"

    # Load the MALLET model
    mallet = Mallet(output_dir=mallet_output_dir)

    # Extract cell-topic and region-topic distributions
    cell_topics = mallet.get_cell_topics(i)
    region_topics = mallet.get_region_topics(i)

    # Save cell-topic matrix
    cell_topics.to_csv(output_file, sep="\t")
    region_topics.to_csv(output_file2, sep="\t")

    print(f"Saved cell-topic matrix with {i} topics to: {output_file}")

