#!/usr/bin/env cwl-runner
cwlVersion: v1.2
class: Workflow

label: "Kinetic Energy Workflow"
doc: >
  Computes kinetic energy from distance, time, and mass.
  Step 1 (get_speed): computes speed = distance / time.
  Step 2 (get_kinetic_energy): computes KE = 0.5 * mass * speed^2.

inputs:
  distance:
    type: float
    label: "Distance"
    doc: "Distance in meters"
  time:
    type: float
    label: "Time"
    doc: "Time in seconds"
  mass:
    type: float
    label: "Mass"
    doc: "Mass in kilograms"

outputs:
  kinetic_energy:
    type: float
    label: "Kinetic Energy"
    doc: "Kinetic energy in joules"
    outputSource: get_kinetic_energy/kinetic_energy

steps:
  get_speed:
    label: "Compute Speed"
    doc: "Computes speed = distance / time"
    in:
      distance:
        source: distance
      time:
        source: time
    out: [speed]
    run: get_speed.cwl

  get_kinetic_energy:
    label: "Compute Kinetic Energy"
    doc: "Computes kinetic energy = 0.5 * mass * velocity^2"
    in:
      mass:
        source: mass
      velocity:
        source: get_speed/speed
    out: [kinetic_energy]
    run: get_kinetic_energy.cwl
