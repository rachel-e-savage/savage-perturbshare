## mamba activate tmtoolkit

import tmtoolkit
import pandas as pd
import numpy as np
import scanpy as sc


adata = sc.read_h5ad("/mnt/users/rachelsavage/paper_minimorf/data/atac_matrices/full_atac_dedup.h5ad")
X = adata.X
X_bin = X.copy()
X_bin.data = np.ones_like(X_bin.data)

row_sums = np.asarray(X_bin.sum(axis=1)).astype(float)


cell_topics_dict = {}
peak_topics_dict = {}

for i in [5, 50, 75, 100, 125, 150, 175, 200]:
    # Define input/output paths for this number of topics
    cell_topics_df = f"/fab/AlignedData/rsav_minimorf/paper_data/atac_cistopic/out_matrices/celltopic{i}.txt"
    cell_topics_dict[f"cell_topics{i}_df"] = pd.read_csv(cell_topics_df, sep="\t", index_col=0)

    peak_topics_df = f"/fab/AlignedData/rsav_minimorf/paper_data/atac_cistopic/out_matrices/peaktopic{i}.txt"
    peak_topics_df = pd.read_csv(peak_topics_df, sep="\t", index_col=0).T
    peak_topics_dict[f"peak_topics{i}_df"] = peak_topics_df.to_numpy()


results = []


for i in [5, 50, 75, 100, 125, 150, 175, 200]:

    metric_arun_2010 = tmtoolkit.topicmod.evaluate.metric_arun_2010(topic_word_distrib=peak_topics_dict[f"peak_topics{i}_df"], doc_topic_distrib=cell_topics_dict[f"cell_topics{i}_df"],doc_lengths=row_sums)

    metric_cao_juan_2009 = tmtoolkit.topicmod.evaluate.metric_cao_juan_2009(topic_word_distrib = peak_topics_dict[f"peak_topics{i}_df"])

    metric_coherence_mimno_2011 = tmtoolkit.topicmod.evaluate.metric_coherence_mimno_2011(peak_topics_dict[f"peak_topics{i}_df"], X_bin, top_n=20, eps=1e-12,normalize=True, return_mean=False)

    final_mimno = np.mean(metric_coherence_mimno_2011[np.argpartition(metric_coherence_mimno_2011, -5)[-5:]])

    results.append({"n_topics": i, "metric_arun_2010": metric_arun_2010, "metric_cao_juan_2009": metric_cao_juan_2009, "metric_coherence_mimno_2011": final_mimno})


results_df = pd.DataFrame(results)
results_df.to_csv("/fab/AlignedData/rsav_minimorf/paper_data/atac_cistopic/metrics.final.csv")

