#!/usr/bin/env bash
{
    DATASET="reddit"
    GPUID="[0,1,2,3,4,5,6,7]" # Length of this list should be equal or larger to WORLD_SIZE
    WORLD_SIZE=4
    AGGREGATE_EVERY=2min
    TRAIN_TIME=4h
    N_DIM=256 # Dimension of hidden representation

    ## For SuperTMA
    GRP_STRATEGY=uniform-cluster
    NUM_PARTS=15000 # This can be changed as the number of super-nodes to be generated by METIS.
    AVG_OPERATOR="average"
    BALANCE_EDGES=false # Set to true when the NUM_PARTS is very close to the number of trainers.

    ## For RandomTMA
    # GRP_STRATEGY=uniform-cluster
    # NUM_PARTS=15000 # This does not affect the final performance, but it should still be set.
    # AVG_OPERATOR="average"
    # BALANCE_EDGES=false # This does not has any effect on RandomTMA.

    ## For PSGD-PA
    # GRP_STRATEGY=uniform-cluster
    # NUM_PARTS=$((WORLD_SIZE-1)) # This should not be changed.
    # AVG_OPERATOR="average"
    # BALANCE_EDGES=true

    ## For LLCG
    # GRP_STRATEGY=uniform-cluster
    # NUM_PARTS=$((WORLD_SIZE-1)) # This should not be changed.
    # AVG_OPERATOR="llcg"
    # BALANCE_EDGES=true

    set -x

    for MODEL in GCN GraphSAGE MLP
    do
        for RND_SEED in 3635683305 442986796
        do
            for GRP_STRATEGY in uniform-cluster random-nodes
            do
                dvc exp run --temp gnn_links "$@" -S model=${MODEL} \
                    -S train.dataset="$DATASET" \
                    -S "train.time_limit=${TRAIN_TIME}" \
                    -S "distributed.AvgCluster.sync_every=${AGGREGATE_EVERY}" \
                    -S "train.random_seed=$RND_SEED" \
                    -S "models.${MODEL}.batch_size=[131072,null]" \
                    -S "models.${MODEL}.model_params.hidden_dims=[$N_DIM,$N_DIM]" \
                    -S "models.${MODEL}.model_params.decoder_n_layers=2" \
                    -S "models.${MODEL}.model_params.decoder_hidden_dims=$N_DIM" \
                    -S "distributed.gpu=${GPUID}" \
                    -S "distributed.AvgCluster.avg_operator=${AVG_OPERATOR}" \
                    -S "distributed.AvgCluster.group_strategy=${GRP_STRATEGY}" \
                    -S "distributed.world_size=${WORLD_SIZE}" \
                    -S "distributed.AvgCluster.num_parts=${NUM_PARTS}" \
                    -S "distributed.AvgCluster.balance_edges=${BALANCE_EDGES}"
            done
        done
    done

    exit
}