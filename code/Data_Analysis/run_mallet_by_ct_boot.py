#!/usr/bin/env python

import argparse
import os
import scanpy as sc
import numpy as np
import numpy as np
import pandas as pd

rng = np.random.default_rng()
# adjust import if needed
from scmallet import Mallet
import random

import math

def resolve_num(num, N):
    if num != 'auto':
        return int(num)

    # 50% of data, rounded up to nearest 1000
    auto = math.ceil(0.5 * N / 1000) * 1000

    # enforce bounds
    auto = max(1000, auto)
    auto = min(100000, auto)

    return auto
    
    
def main(ct: str, index: int, num, bc=None):
    # paths
    h5ad_path = f"./h5ads/{ct}.h5ad"
    outdir = f"./topics_boot_v3/{ct}/{index}"
    os.makedirs(outdir, exist_ok=True)

    
    # MALLET model
    model = Mallet(outdir)

    # topic numbers (keep your pattern)
    topic_nums = [100]
    seed = int(rng.integers(0, 1000))
    for topic_num in topic_nums:
        print(f"[INFO] Loading {h5ad_path}")
        rna_adata = sc.read_h5ad(h5ad_path)

        if bc is not None:
            bc = pd.read_csv(bc, sep='\t')
            bc = list(bc.iloc[:, 0])
            shared = list(set(bc) & set(rna_adata.obs_names))
            rna_adata = rna_adata[shared].copy()
            print ("slicing anndata to", rna_adata.shape)
    
        num = resolve_num(num, rna_adata.n_obs)
    
        # optional sanity log
        print(f"[INFO] Cells: {rna_adata.n_obs}, Genes: {rna_adata.n_vars}")
    
        sc.pp.sample(rna_adata, n=num, replace=True)
        rna_adata.obs_names_make_unique()
    
        print(f"[INFO] Sampled Cells: {rna_adata.n_obs}, Genes: {rna_adata.n_vars}")

    
        model.fit(
            topic_num,
            rna_adata,
            cpu_per_task=32,
            mem_gb=256,
            iterations=500,
            random_seed=seed,
        )



if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Run MALLET per cell type")
    parser.add_argument(
        "--ct",
        required=True,
        help="Cell type / cluster annotation (must match h5ads/{ct}.h5ad)",
    )
    parser.add_argument(
        "--id",
        required=True,
        help="Cell type / cluster annotation (must match h5ads/{ct}.h5ad)",
    )
    parser.add_argument(
        "--num",
        required=False,
        default='auto')
    parser.add_argument(
        "--bc",
        required=False,
        default=None)

    args = parser.parse_args()
    main(args.ct, args.id, args.num, args.bc)