import sys
from scmallet import Mallet
import anndata as ad
import numpy as np

topic = int(sys.argv[1])

mallet = Mallet(output_dir=f"/n/holylfs06/LABS/buenrostro_lab/Users/rsavage/minimorf/final_terra/cistopic/cistopics{topic}")

#data = ad.read_h5ad('/n/holylfs06/LABS/buenrostro_lab/Users/rsavage/minimorf/final_terra/cistopic/fullatac.h5ad')
#data = ad.read_h5ad('/n/holylfs06/LABS/buenrostro_lab/Users/rsavage/minimorf/final_terra/cistopic/testatac.h5ad')

data = ad.read_h5ad('/n/holylfs06/LABS/buenrostro_lab/Users/rsavage/minimorf/final_terra/cistopic/full_atac_dedup.h5ad')


data.X.data = np.ones_like(data.X.data, dtype=int)

mallet.fit(
    num_topics=[topic],
    data=data,
    cpu_per_task=32,
    mem_gb=100,
    iterations=300,
)
