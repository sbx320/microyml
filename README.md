# MicroYML

[![justforfunnoreally.dev badge](https://img.shields.io/badge/justforfunnoreally-dev-9ff)](https://justforfunnoreally.dev)
![Static Badge](https://img.shields.io/badge/Built_with-Lua-blue?logo=lua)

This is a nifty, *tiny* little tool I threw together in Lua for a Love2D project that needed minimal YAML support. This little project is not compliant with the YAML 1.1 standard in its entirety. This subset of YAML is incredibly small and is effectively purpose-built for the bare minimum. I decided to make this free and open-source the project for everyone to use in projects and areas where all you need is an incredibly small parser for basic YAML and nothing else, almost no headroom and insanely fast runtimes.

This entire implementation is just about 200 lines of Lua code. This is pure lua so it can also be included in LuaJIT environments. This implementation is also licensed under MIT, so you can use it anywhere as long as attribution is provided.

## How-to Write MicroYML

MicroYML is a significantly cut down subset of the YAML standard. While YAML itself can be as extensive as this example:
```yaml
# Example of compliant yaml in a game-dev context
id: slime
name: "Slime King"
hp: 12
atk: 3
drops:
  item:
    - name: "coin"
    - amt: 156
abilities:
  - &fireball
    name: Fireball
    damage: 10
  - name: Ice Blast
    damage: 8
merge_example: *fireball
dialogue: |
  The slime hisses and jumps.
  "You'll never defeat me!"
boss: false
```

MicroYML is far more cut-down, the essentials for YAML data:
```yaml
# The same example, but now with microyml
id: slime
name: "Slime King"
hp: 12
atk: 3
drops:
  item:
    - name: "coin"
    - amt: 156
abilities:
  - name: Fireball
    damage: 10
  - name: Ice Blast
    damage: 8
dialogue: "The slime hisses and jumps. \"You'll never defeat me!\""
boss: false
```

And that's about it for MicroYML. I may come back to this periodically and implement some more YAML 1.1 features and fix the many bugs on an "as requested" or "as needed" basis. If you all have suggestions or issues with this project, open up an issue, or if you would like to submit a fix or new feature, send a pull request over!

> Thanks for using microyaml, may it serve your project well! o7
