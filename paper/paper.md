---
title: 'greta: simple and scalable statistical modelling in R'
tags:
  - statistics
  - statistical modelling
  - bayesian statistics
  - mcmc
  - hamiltonian monte carlo
  - tensorflow
authors:
  - name: Nick Golding
    orcid: 0000-0001-8916-5570
    affiliation: 1
affiliations:
 - name: School of BioSciences, University of Melbourne
   index: 1
date: 27 June 2019
bibliography: paper.bib
output:
  html_document:
    keep_md: yes
---

# Summary

Statistical modelling useful throughout the sciences. Often a need to write custom models that cannot be fitted using off-the shelf statistical software (such as software for for fitting mixed effects models). Hence writing out the model in a modelling language and fitting them by MCMC or maximum likelihood. This lets the user focus on the statistical nature of the model, rather than implementation details and inference procedures. This has lead to the development of software including BUGS, JAGS and NIMBLE [@openbugs; @jags; @nimble]. In these software packages, users typically write out models in a domain-specific language which is then compiled into computational code - though see the Python packages PyMC and Edward [@pymc; @edward].

With increasing quantitites of data and increasing complexity and realism of the statistical models that users wish to buiold with these software, ther is a push for software that scales better with data size and model complexity. Therefore using Hamiltonian Monte Carlo rather than Gibbs samplers, and paying particular attention to computational efficiency (Stan) [@stan].

greta is an R package for statistical modelling that has three core differences to commonly used statistical modelling software packages:

  1. greta models are written interactively in R code rather than in a compiled domain specific language.
  2. greta can be extended by other R packages; providing a fully-featured package management system for extensions.
  3. greta performs statistical inference using TensorFlow [@tf] enabling it to scale across modern high-performance computing systems.
  
greta can be used to construct both Bayesian and non-Bayesian statistical models, and perform inference via MCMC or optimisation (for maximum likelihood or maximum *a posteriori* estimation). The default MCMC algorithm is Hamiltonian Monte Carlo, which is generally very efficient for Bayesian models with large numbers of parameters or highly-correlated posteriors.

The project website [https://greta-stats.org/]() hosts a *getting started* guide, worked examples of analyses using greta, a catalogue of example models, documentation, and a user forum.

# demonstration

The following illustrates a typical modelling session with greta, using a
Bayesian hierarchical model to estimate the treatment effect of epilepsy
medication using data provided in the MASS R package (@mass, distributed
with R) and analysed in the corresponding book.




Before we specify the greta model, we format the data to make out lives
easier; adding a numeric version of the treatment type and making a vector of
the (8-week) baseline counts for each subject (these counts are replicated in
the epil object).


```r
library(MASS)
epil$trt_id <- as.numeric(epil$trt)
baseline_y <- epil$base[!duplicated(epil$subject)]
```

Next we load greta and start building our model, starting with a random
intercept model for the baseline (log-)seizure rates, to account for the fact
that each individual will have a different seizure rate, irrespective of
the treatment they receive.


```r
library(greta)

# priors
subject_mean <- normal(0, 10)
subject_sd <- cauchy(0, 1, truncation = c(0, Inf))

# hierararchical model for baseline rates (transformed to b positive)
subject_effects <- normal(subject_mean, subject_sd, dim = 59)
baseline_rates <- exp(subject_effects)
```

Next we build model for the effects (the ratio of post-treatment to
pre-treatment seizure rates) of the two treatments: placebo and progabide. We
give these positive-truncated normal priors (they are multiplicative effects,
so must be positive), and centre them at 1 to represent a prior expectation of
no effect. We multiply these effects by the baseline rates to get the
post-treatment rates for each observation in the dataset.


```r
# prior
treatment_effects <- normal(1, 1, dim = 2, truncation = c(0, Inf))
post_treatment_rates <- treatment_effects[epil$trt_id] * baseline_rates[epil$subject]
```

Finally we specify the distributions over the observed data. Here we use two
likelihoods: one for the baseline count (over an 8 week period) and one for
each of the post-treatment counts (over 2 week periods). We multiply our
modelled weekly rates by the number of weeks the counts represent to get the
appropriate rate for that period.


```r
distribution(baseline_y) <- poisson(baseline_rates * 8)
distribution(epil$y) <- poisson(post_treatment_rates * 2)
```

Now we can create a model object using these greta arrays, naming the
parameters that we are most interested in, and then run an MCMC sampler on the
model.


```r
m <- model(treatment_effects, subject_sd)
draws <- mcmc(m)
```

The ``draws`` object contains posterior samples in an `mcmc.list` object from
the coda package [@coda], for which there are many packages and utilities to
summarise the posterior samples. Here' we'll use the bayesplot package
[@bayesplot] to create trace plots for the parameters of interest, and the
coda package to get $\hat{R}$ statistics to assess convergence of these parameters.


```r
bayesplot::mcmc_trace(draws)
```

![](paper_files/figure-html/diagnostics-1.png)<!-- -->

```r
coda::gelman.diag(draws)
```

```
## Potential scale reduction factors:
## 
##                        Point est. Upper C.I.
## treatment_effects[1,1]          1       1.01
## treatment_effects[2,1]          1       1.00
## subject_sd                      1       1.01
## 
## Multivariate psrf
## 
## 1
```

We can summarise the posterior samples to get the treatment effect estimates
for placebo and progabide, the first and second elements of
`treatment_effects` respectively.


```r
summary(draws)$statistics
```

```
##                             Mean         SD     Naive SE Time-series SE
## treatment_effects[1,1] 1.1176199 0.05278737 0.0008346416   0.0011645811
## treatment_effects[2,1] 1.0107183 0.04462845 0.0007056378   0.0008762349
## subject_sd             0.7991257 0.07826540 0.0012374846   0.0014946363
```

These parameter estimates tell us the ratio of seizures rates during and
before the treatment period for both the drug and placebo treatments. To
calculate the drug effect, we would take the ratio of the seizure rates
between the drug treatment and the placebo. We didn't include that term in our
model, but fortunately there's no need to re-fit the model. greta's
`calculate()` function lets us compute model quantities after model fitting.


```r
# create a drug effect greta array and calculate posterior samples of this
drug_effect <- treatment_effects[2] / treatment_effects[1]
drug_effect_draws <- calculate(drug_effect, draws)
summary(drug_effect_draws)$statistics
```

```
##           Mean             SD       Naive SE Time-series SE 
##   0.9063622467   0.0585752902   0.0009261567   0.0012205338
```

`calculate()` can also be used for posterior prediction, enabling greta to be
used in a predictive modelling workflow without knowing the prediction data
before model fitting, or having to hand-code the predictions for all posterior
samples.

# Implementation

R front end, extending existing R functions.
using R6 objects internally to build up a DAG
Using the DAG to construct a likelihood function using TensorFlow
Using TensorFlow [@tf] and TensorFlow Probability [@tfp] via reticulate and the tensorflow R API [@reticulate; @r_tf] functionality for the core computational part of inference.
Whereas most MCMC software packages enable each MCMC chain to run on a separate CPU, greta can parallelise MCMC on a single chain across an arbitrary number of CPUs by parallelising 
By simply installing the appropriate version of TensorFlow, greta models can also be run on Graphics Processing Units (GPUs).
greta is also integrated with the future R package [@future] for remote and parallel processing, providing a simple interface to run inference for each chain of MCMC on a separate, remote machines.

# extending greta

greta is not only designed to be extensible, but makes a deliberately distinction between the API for *users* who construct statistical models using existing functionality, and *developers* who add new functionality. Rather than letting users directly modify the inference target within a model, new probability distributions and operations are created using a developer user interface, exposed via the `.internals` object. Once developed in this way, it becomes simple to distribute this new functionality to other users via an R package that extends greta. Linking to the well established R package mechanism means that ``greta`` extensions automatically come with a  fully-featured package management system, with tooling for development and distribution via CRAN or code sharing platforms.

This developer API is under active development to make the process of extending greta simpler. Whilst anyone can write and distribute their own extension package, an aim of the greta project is to maintain a set of extension packages that meet software quality standards and are completely interoperable, in a similar way to the 'tidyverse' of R packages [@tidyverse] for data manipulation. These packages will be hosted on both the project GitHub organisation at [https://github.com/greta-dev/]() and on CRAN.
There are currently a number of extensions in prototype form hosted on the GitHub organisation, including extensions to facilitate Gaussian process modelling (greta.gp), modelling dynamic systems (greta.dynamics) and generalised additive modelling (greta.gam).

# future work

### discrete parameters

greta currently only handles models with exclusively continuous-valued parameters, since these models are compatible with the most commonly used optimisation routines and the efficient HMC sampler that is used by default. In the near future, greta will be extended to enable users to perform inference on models with discrete-valued parameters as required, in combination with the (typically less efficient) samplers with which these models are compatible.

### marginalisation

Many common statistical modelling approaches, such as hierarchical models, use unobserved *latent* variables whose posterior distributions must be integrated over in order to perform inference on parameters of interest. Whilst MCMC is a general-purpose method for marginalising these parameters, other methods are often better suited to the task in specific models. For example where those latent variables are discrete-valued and efficient samplers cannot be used, or when deterministic numerical approximations such as a Laplace approximation are more computationally-efficient. A simple user interface to specifying these marginalisation schemes within a greta model is planned. This will enable users to experiment with combinations of different inference approaches without the need delve into nuances of implementation.

# Acknowledgements

I'd like to acknowledge direct contributions from Simon Dirmeier, Adam Fleischhacker, Shirin Glander, Martin Ingram, Lee Hazel, Tiphaine Martin, Matt Mulvahill, Michael Quinn, David Smith, Paul Teetor, and Jian Yen, as well as Jeffrey Pullin and many others who have provided feedback and suggestions on greta and its extensions. ``greta`` was developed with support from both a McKenzie fellowship from the University of Melbourne, and a DECRA fellowship from the Australian Research Council (DE180100635).

# References