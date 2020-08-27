import os
import flag
// import markdown


fn exec(s string) string {
	e := os.exec(s) or { panic(err) }
	return e.output.trim_right("\r\n")
}



fn main() {

// Template for changelog
template := "# Changelog
"

additive_template := "# Changelog
## {{ver}} {{date}}
"

	mut vlog := flag.new_flag_parser(os.args)

	vlog.skip_executable()
	vlog.application("vlog")
	vlog.version("0.0.1")
	vlog.description("Generates a readable change log based on git commits")

	additive := vlog.bool("additive", `a`, true, "add to the previous log")
	path := vlog.string("path", `p`, ".", "path to repo")
	out := vlog.string("out", `o`, "./CHANGELOG.md", "Path to output md changelog to")
	help := vlog.bool("help", `h`, false, "Display this help text")
	mut version := vlog.string("version", `v`, "0.0.1", "Path to output md changelog to")

	if help {
		println(vlog.usage())
	}

	mut changes := map[string][]string

	// changes["added"] = []string
	// changes["changed"] = []string
	// changes["deprecated"] = []string
	// changes["removed"] = []string
	// changes["fixed"] = []string
	// changes["security"] = []string

	// Check we're in a git folder
	if os.exists(".git") {

		mut command := "git log --oneline"

		// Get last release
		r := exec("git for-each-ref --sort=creatordate --format '%(refname) %(creatordate)' refs/tags/")

		// If there's ever been a release
		if r != "" {
			lines := r.split("\n")
			version = lines[lines.len-1].split(" ")[0]
			version = version[11..version.len]
			command = command + " " + version + "..master"
		}

		// Run command and store output
		log := exec(command)

		commits := log.split("\n")

		mut ids := []string

		for commit in commits {

			short :=commit.split(" ")[0]
			ids << short

			// Get commit info
			info := exec("git show " + short + " -s --format=%B")

			// println(info.split("\n"))

			for line in info.split("\n") {

				// If the line's empty, skip
				if line == "" { continue }

				split := line.split(" ")

				mut first := split[0].to_lower()

				// If there's a :, remove it
				if first.ends_with(":") {
					first = first[0..first.len-1]
				}


				match first {
					// for new features.
					"added"
						{ changes["added"] << split[1..split.len].join(" ")	}
					// for changes in existing functionality.
					"changed"
						{ changes["changed"] << split[1..split.len].join(" ") }
					// for soon-to-be removed features.
					"deprecated"
						{ changes["deprecated"] << split[1..split.len].join(" ")	}
					// for now removed features.
					"removed"
						{ changes["removed"] << split[1..split.len].join(" ") }
					// for any bug fixes.
					"fixed"
						{ changes["fixed"] << split[1..split.len].join(" ") }
					// in case of vulnerabilities.
					"security"
						{ changes["security"] << split[1..split.len].join(" ") }
					else { continue }
				}
			}
		}


		os.write_file("CHANGELOG.md", changes.str())


	} else {
		println("Not in a git project")
		exit(1)
	}
}
