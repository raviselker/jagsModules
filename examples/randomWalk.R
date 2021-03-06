#### Prepare the data ----

library('tidyverse')

dataPre <- read.csv("data/LessIsMoreData.csv") %>% 
    filter(country == 2, recogA == 1, recogB == 1) %>%  # German cities that were recognized
    select(-country, -recogA, -recogB) %>%              # Remove unnecessary columns
    mutate(decision = abs(decision - 2))                # Recode decision (1 = A, 0 = B)

stimA <- dataPre$stimA
stimB <- dataPre$stimB
dec <- dataPre$decision

nTrials <- nrow(dataPre)

coding <- R.matlab::readMat('data/FeatureEnvironments.mat')$d[,,1]
val <- as.numeric(coding$validity)
val1 <- rep(1, length(val))                             # Set all validities to 1
cues <- coding$cues
nCues <- length(val)

data <- list(dec=dec, stimA=stimA, stimB=stimB, val=val, 
             val1=val1, cues=cues, nCues=nCues, nTrials=nTrials)


#### Define the TTB model ----

TTB <- '
model {
    for (i in 1:nTrials) {
        out[i,1:3] <- randomWalk(cues[stimA[i],], cues[stimB[i],], val1, s, nCues, 0, 1)
        choice[i] <- out[i,1]
        ev[i] <- out[i,3]
        dec[i] ~ dbern(equals(choice[i],1)*(1-gamma) + equals(choice[i],0)*gamma + equals(choice[i], 0.5)*0.5)
    }

    s <- order(-val)
    gamma ~ dunif(0, 0.5)
}'

pTTB <- '
model {
    for (i in 1:nTrials) {
        out[i,1:3] <- randomWalk(cues[stimA[i],], cues[stimB[i],], val1, s, nCues, 0, 1)
        choice[i] <- out[i,1]
        nChoice[i] <- out[i,2]
        ev[i] <- out[i,3]
        dec[i] ~ dbern(equals(choice[i],1)*(1-gamma[nChoice[i]]) + equals(choice[i],0)*gamma[nChoice[i]] + equals(choice[i], 0.5)*0.5)
    }

    s <- order(-val)
    for (c in 1:nCues) {
        gammaTemp[c] ~ dunif(0,0.5)
    }
    
    gamma <- sort(gammaTemp)
}'


#### Define the TALLY model ----

TALLY <- '
model {
    for (i in 1:nTrials) {
        out[i,1:3] <- randomWalk(cues[stimA[i],], cues[stimB[i],], val1, s, nCues, 0, nCues + 1)
        choice[i] <- out[i,1]
        ev[i] <- out[i,3]
        dec[i] ~ dbern(equals(choice[i],1)*(1-gamma) + equals(choice[i],0)*gamma + equals(choice[i], 0.5)*0.5)
    }

    s <- order(-val)
    gamma ~ dunif(0, 0.5)
}'


#### Define the WASS model ----

WADD <- '
model {
    for (i in 1:nTrials) {
        out[i,1:3] <- randomWalk(cues[stimA[i],], cues[stimB[i],], val, s, nCues, 0, sum(val) + 1)
        choice[i] <- out[i,1]
        ev[i] <- out[i,3]
        dec[i] ~ dbern(equals(choice[i],1)*(1-gamma) + equals(choice[i],0)*gamma + equals(choice[i], 0.5)*0.5)
    }

    s <- order(-val)
    gamma ~ dunif(0, 0.5)
}'

pWADD <- '
model {
    for (i in 1:nTrials) {
        out[i,1:3] <- randomWalk(cues[stimA[i],], cues[stimB[i],], val, s, nCues, 0, sum(val) + 1)
        choice[i] <- out[i,1]
        ev[i] <- out[i,3]
        dec[i] ~ dbern(1 / (1 + exp(-alpha*ev[i])))
    }

    s <- order(-val)
    alpha ~ dnorm(0, 1/100)
}'


#### Fit the model ----

nchains  <- 1      # number of markov chains
nburnin  <- 1000   # number of burnin samples
nsamples <- 10000  # total number of samples
nthin    <- 1      # thinning per chain

rjags::load.module('wfComboPack')


model <- rjags::jags.model(file = textConnection(pWADD),
                           data = data,
                           n.chains = nchains)

update(model, nburnin)
samples <- rjags::coda.samples(model, c('choice', 'ev', 'alpha'), nsamples, thin=nthin)


#### Check results ----

plot(density(samples[['gamma']][1,,]))
