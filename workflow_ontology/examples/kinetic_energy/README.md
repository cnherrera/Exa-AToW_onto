# Kinetic Energy — CWL Workflow Example

This example shows how to convert a CWL workflow into an OWL/Turtle knowledge graph instance using the **Exa-AToW Workflow** ontologies, and how to visualise it interactively in a browser.

It is based on the canonical example from [**semantikon**](https://github.com/pyiron/semantikon), a Python library for annotating functions with semantic metadata (units, ontology URIs). The original workflow uses `semantikon`'s `u()` decorator to attach RDF annotations to function parameters — here we convert it to CWL and instantiate it as an OWL knowledge graph using the Exa-AToW Workflow ontologies.

The workflow modelled:

```python
from semantikon import u
from rdflib import Namespace
EX = Namespace("http://example.org/")

def get_speed(
    distance: u(float, uri=EX.distance, units="meter"),
    time:     u(float, uri=EX.time,     units="second"),
) -> u(float, uri=EX.speed, units="meter/second"):
    return distance / time

def get_kinetic_energy(
    mass:     u(float, units="kilogram",     uri=EX.Mass),
    velocity: u(float, units="meter/second", uri=EX.Velocity),
) -> u(float, units="joule", uri=EX.KineticEnergy):
    return 0.5 * mass * velocity**2

def my_kinetic_energy_workflow(distance, time, mass):
    speed          = get_speed(distance, time)       # step 1
    kinetic_energy = get_kinetic_energy(mass, speed) # step 2
    return kinetic_energy
```

> The semantic annotations (`uri=`, `units=`) are not yet reflected in the CWL/OWL conversion — this is planned for a future version.

---

## Folder contents

```
examples/kinetic_energy/
├── kinetic_energy_workflow.cwl      ← main CWL Workflow (entry point)
├── get_speed.cwl                    ← CWL tool: speed = distance / time
├── get_kinetic_energy.cwl           ← CWL tool: KE = 0.5 · mass · velocity²
├── kinetic_energy_instance.ttl      ← pre-generated OWL instance (ready to view)
└── README.md                        ← this file
```

The conversion script and viewer live at the repo root:

```
├── tools/cwl_to_ttl.py              ← CWL → Turtle converter
└── viewer/onto-viewer.html          ← browser-based ontology visualiser
```

---

## Prerequisites

- Python 3.10+
- A modern browser (Firefox, Chrome)

Install Python dependencies:

```bash
pip install rdflib pyyaml
```

---

## Step 1 — Generate the Turtle instance

A pre-generated `kinetic_energy_instance.ttl` is already included — you can skip straight to [Step 2](#step-2--visualise-with-onto-viewerhtml) if you just want to visualise it.

To regenerate it from the CWL files, run from this folder:

```bash
python ../../tools/cwl_to_ttl.py kinetic_energy_workflow.cwl \
    -o kinetic_energy_instance.ttl \
    --base "http://example.org/kinetic_energy#"
```

Expected output:

```
Reading  : kinetic_energy_workflow.cwl
Base NS  : http://example.org/kinetic_energy#
Output   : kinetic_energy_instance.ttl
Done — 152 triples written to kinetic_energy_instance.ttl
```

### What the script generates

| Individual | Type | Description |
|---|---|---|
| `inst:wf_Kinetic_Energy_Workflow` | `CWLWorkflow` | The workflow itself |
| `inst:step_get_speed` | `CWLWorkflowStep` | Step 1 |
| `inst:step_get_kinetic_energy` | `CWLWorkflowStep` | Step 2 |
| `inst:tool_get_speed` | `CWLCommandLineTool` | Tool behind step 1 |
| `inst:tool_get_kinetic_energy` | `CWLCommandLineTool` | Tool behind step 2 |
| `inst:wf_input_distance/time/mass` | `InputParameter` | Workflow-level inputs |
| `inst:wf_output_kinetic_energy` | `OutputParameter` | Workflow-level output |
| `inst:step_*_in_*` / `inst:step_*_out_*` | `Input/OutputParameter` | Step-level parameters |

Key relationships asserted:

```
inst:wf_Kinetic_Energy_Workflow
    ├── exato-wf:hasStep → inst:step_get_speed
    │       ├── exato-wf:hasInputParameter  → inst:step_get_speed_in_distance
    │       │                               → inst:step_get_speed_in_time
    │       ├── exato-wf:hasOutputParameter → inst:step_get_speed_out_speed
    │       └── exato-wf-cwl:runs          → inst:tool_get_speed
    │
    └── exato-wf:hasStep → inst:step_get_kinetic_energy
            ├── exato-wf:dependsOn          → inst:step_get_speed   ← execution order
            ├── exato-wf:hasInputParameter  → inst:step_get_kinetic_energy_in_mass
            │                               → inst:step_get_kinetic_energy_in_velocity
            ├── exato-wf:hasOutputParameter → inst:step_get_kinetic_energy_out_kinetic_energy
            └── exato-wf-cwl:runs          → inst:tool_get_kinetic_energy

Data link: inst:step_get_speed_out_speed
               → exato-wf:connectsTo → inst:step_get_kinetic_energy_in_velocity
```

`exato-wf:dependsOn` is inferred automatically from the CWL `source:` wiring: because `get_kinetic_energy` takes `get_speed/speed` as input, the script asserts that it depends on `get_speed`.

---

## Step 2 — Visualise with onto-viewer.html

Open `../../viewer/onto-viewer.html` in your browser.

### Load the instance
You can either open a ttl file online or upload it from your local machine:
1. Click the **folder icon** in the top-left toolbar.
2. Select `kinetic_energy_instance.ttl` from this folder.
3. The graph renders automatically.

> **Note:** The viewer will attempt to fetch the `owl:imports` URLs declared in the TTL. If you are offline or behind a firewall, the imports are silently skipped — the graph still renders correctly because the minimal TBox (classes and properties used in this instance) is embedded directly in the TTL.



### Navigation

| Action | How |
|---|---|
| Pan | Click and drag on the canvas |
| Zoom | Scroll wheel |
| Inspect a node | Click on it — details appear in the right panel |
| Show/hide instances | Toggle **Instances** in the toolbar |
| Show/hide edge labels | Toggle **Edge labels** in the toolbar |
| Fit to screen | Click the **⤢ Fit** button |

---

## Using cwl_to_ttl.py with your own CWL workflow

The script is general — it works with any CWL Workflow file. Place your files in a folder following this layout:

```
my_workflow/
├── my_workflow.cwl        ← entry point (class: Workflow)
├── tool_a.cwl             ← referenced by run: tool_a.cwl
└── tool_b.cwl
```

Then run:

```bash
python ../../tools/cwl_to_ttl.py my_workflow.cwl \
    -o my_workflow_instance.ttl \
    --base "http://example.org/my_workflow#"
```

| Flag | Default | Description |
|---|---|---|
| `cwl_file` | *(required)* | Path to the CWL Workflow file |
| `-o`, `--output` | `<cwl_stem>_instance.ttl` | Output Turtle file path |
| `--base` | `http://example.org/<cwl_stem>#` | Base namespace URI for all generated instances |

---

## Troubleshooting

**Syntax error on TTL load in the viewer**
Validate the file first:
```bash
python3 -c "from rdflib import Graph; g = Graph(); g.parse('kinetic_energy_instance.ttl')"
```

**Steps appear but no edges between them**
Check that your CWL steps use `source:` fields to wire inputs — these are what the script uses to infer `dependsOn` and `connectsTo` links.
