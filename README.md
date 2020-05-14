# NetLogo code and data for project on social distancing effects on small world networks.

This repository contains the NetLogo code and data files used for this project.

# Description of Model

In our model, each agent carries an individual pathogen level that varies over time.
Initially, this level is set to 0 pathogen units for susceptible agents.
At each time step (conceived as a day) a susceptible agent increases their pathogen level by a fixed fraction of the pathogen levels of their infected neighbors. 
Model runs are initiated with a small number of infected agents, whose pathogen levels are initially set at 35 pathogen units, and the remainder of the agents are initially deemed susceptible.
In our model, there is a global pathogen-level infection threshold that applies to all agents. 
We fixed that threshold to 25 pathogen units. 
If the pathogen level for an agent exceeds this threshold, then they become infected.
These initial and threshold levels for the pathogen in the model are not based on real-world data, but rather were selected for simplicity to illustrate the mechanism of viral shedding.

Following the onset of infection, agents pass through an initial asymptomatic infection state, followed by a main infection state (either symptomatic or asymptomatic), before being removed from the system.
The length of the initial asymptomatic state is the same for all agents, and can be set to last one or more days.
Once the initial asymptomatic state passes, the agent enters one of two main states: infected and asymptomatic or infected and symptomatic.
The lengths of the two main states are set independently from each other, but are the same for all agents.
Following the main infection state, the agent is resistant/removed.

In addition to having an infection state influenced by various model parameters, each agent is in one of two behavior states: socially distanced or not socially distanced.
The behavior state is reset each day.
If an agent is not socially distanced on a given day, then they interact with all neighboring agents.
If an agent is socially distanced, they do not interact with any neighboring agents.
Agents socially distance in a given day for one of two reasons.
A global social distance chance is set, which determines the chance that an agent will socially distance on a given day.
A local social distance threshold is set, and this value dictates individual responses to infected symptomatic neighbors.
If the number of infected symptomatic neighbors of an agent exceeds this threshold, the agent will social distance independently of the global parameter.
The model also includes a parameter for virus infectivity, which determines the rate of pathogen shedding from infected agents.
