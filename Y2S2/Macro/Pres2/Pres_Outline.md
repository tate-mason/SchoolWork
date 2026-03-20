# Outline of Presentation

This is for a 2 hour presentation on neural network estimation, inspired by the paper [Estimating Parameters of Structural Models using Neural Networks](https://pubsonline.informs.org/doi/10.1287/mksc.2022.0360) I want the presentation to loosely follow this outline.

Prerequisites:
- Use beamer in latex
- use minted package in latex for code
- if something is vague, do not add it i will find it
- when referencing literature, put a downloaded copy (when available) in a folder you will create called Readings/
- align with my style in presentation found in ~/SchoolWork/Y2S2/Macro/Pres1/Mason_Pres1.tex


## Introduction
> Brief overview of what a neural network is 
> Machine learning models in economics - background
> What is the use case for neural networks in structural modeling

## Brief Neural Network Introduction and Lesson
> Structure of a neural network
  - types of cells, graphics, complexity
> Functions associated with neural networks
  - training
  - loss
  - other
> Training process

## Worked Example: AR(1)
> Follow AR(1) example in paper
  - include code working through the algorithm alongside algorithm in text
> Focus on accuracy and efficiency advantages

## Paper
> Key definitions associated with NNE in paper
  - shallow NN
> Work through search example from their paper

## Conclude:
> When NNE is useful and preferable
> Slides for how it applies to my interests (blank)

## After creating presentation:
> translate the Julia code in ~/SchoolWork/Y2S1/Macro/ResProj/estimation/ to Python
  - keep code simple, I want to learn from it
> create a new folder in ~/SchoolWork/Y2S2/Macro/Pres2/ called Code/ which will hold translated code as well as code which uses NNE to estimate it. NNE can use simulated data instead of real

