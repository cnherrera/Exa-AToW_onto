#!/usr/bin/env cwl-runner
cwlVersion: v1.2
class: CommandLineTool

label: "Get Kinetic Energy"
doc: "Computes kinetic energy = 0.5 * mass * velocity^2. Wraps the get_kinetic_energy Python function."

baseCommand: [python3, get_kinetic_energy.py]

inputs:
  mass:
    type: float
    label: "Mass (kg)"
    doc: "Mass in kilograms"
    inputBinding:
      prefix: --mass
      position: 1
  velocity:
    type: float
    label: "Velocity (m/s)"
    doc: "Velocity in meters per second"
    inputBinding:
      prefix: --velocity
      position: 2

outputs:
  kinetic_energy:
    type: float
    label: "Kinetic Energy (J)"
    doc: "Kinetic energy in joules"
    outputBinding:
      glob: ke_output.json
