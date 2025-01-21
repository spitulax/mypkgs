package main

import (
	"encoding/json"
	"errors"
	"flag"
	"fmt"
	"io"
	"os"
	"os/exec"
	"path/filepath"
)

// `pkgs` and `flakes` are comma-separated
type UpscriptOpts struct {
	pkgs       *string
	flakes     *string
	force      *bool
	flakesOnly *bool
	pkgsOnly   *bool
	skipExist  *bool
}

func NewUpscriptOpts(f *flag.FlagSet) (o UpscriptOpts) {
	o.pkgs = f.String("pkgs", "", "One or more packages to update (comma-separated)")
	o.flakes = f.String("flakes", "", "One or more flakes to update (comma-separated)")
	o.force = f.Bool("force", false, "Update even if the found version is the same as the old version")
	o.flakesOnly = f.Bool("flakes-only", false, "Only update the flakes")
	o.pkgsOnly = f.Bool("pkgs-only", false, "Only update the packages")
	o.skipExist = f.Bool("skip-exist", false, "Skip directories where pkg.json or flake.json already exists")
	return o
}

type SubcommandUpscript struct {
	flags *flag.FlagSet
	UpscriptOpts
}

func NewSubcommandUpscript() (s SubcommandUpscript) {
	s.flags = NewFlagSet(s.Name())
	s.UpscriptOpts = NewUpscriptOpts(s.flags)
	return s
}

func (s SubcommandUpscript) Name() string {
	return "upscript"
}

func (s SubcommandUpscript) Usage() string {
	return "Run the update script of maintained packages and flakes"
}

func (s SubcommandUpscript) Run() error {
	if err := Upscript(s.UpscriptOpts); err != nil {
		return err
	}

	return nil
}

func (s SubcommandUpscript) PrintDefaults(output io.Writer) {
	s.flags.PrintDefaults()
}

func (s SubcommandUpscript) Parse(args []string) {
	s.flags.Parse(args)
}

func Upscript(opts UpscriptOpts) error {
	fmt.Println("\033[1mRunning update scripts...\033[0m")

	var buildPkgs, buildFlakes bool
	if !(*opts.pkgsOnly || *opts.flakesOnly) {
		buildPkgs, buildFlakes = true, true
	} else {
		buildPkgs = *opts.pkgsOnly
		buildFlakes = *opts.flakesOnly
	}

	// NOTE: flakes operations should be first
	var flakesScripts, pkgsScripts string

	if buildFlakes {
		var drvErr error
		flakesScripts, drvErr = NixBuild(".#flakes-update-scripts")
		if drvErr != nil {
			return drvErr
		}
	}

	if buildPkgs {
		var drvErr error
		pkgsScripts, drvErr = NixBuild(".#pkgs-update-scripts")
		if drvErr != nil {
			return drvErr
		}
	}

	// WARNING: A string could be empty
	var flakes, pkgs []string
	relyOnOpts := false

	if buildFlakes {
		if *opts.flakes != "" {
			relyOnOpts = true
			flakes = SplitAndTrim(*opts.flakes, ",")
		} else if !relyOnOpts {
			var err error
			flakes, err = ReadDir(flakesScripts)
			if err != nil {
				return err
			}
		}
	}

	if buildPkgs {
		if *opts.pkgs != "" {
			relyOnOpts = true
			pkgs = SplitAndTrim(*opts.pkgs, ",")
		} else if !relyOnOpts {
			var err error
			pkgs, err = ReadDir(pkgsScripts)
			if err != nil {
				return err
			}
		}
	}

	for _, flake := range flakes {
		if flake != "" {
			if err := UpOne(opts, UpFlake, flake, flakesScripts); err != nil {
				return err
			}
		}
	}

	for _, pkg := range pkgs {
		if pkg != "" {
			if err := UpOne(opts, UpPkg, pkg, pkgsScripts); err != nil {
				return err
			}
		}
	}

	return nil
}

type UpKind uint8

const (
	UpFlake UpKind = iota
	UpPkg
)

func UpOne(opts UpscriptOpts, kind UpKind, name string, scriptDir string) error {
	var containingDir string
	switch kind {
	case UpFlake:
		containingDir = "flakes"
	case UpPkg:
		containingDir = "pkgs"
	}

	dir := filepath.Join(containingDir, name)
	if !IsExist(dir) {
		return fmt.Errorf("UpOne(): `%s` does not exist", dir)
	}

	var jsonPath string
	switch kind {
	case UpFlake:
		jsonPath = filepath.Join(dir, "flake.json")
	case UpPkg:
		jsonPath = filepath.Join(dir, "pkg.json")
	}

	if *opts.skipExist && IsExist(jsonPath) {
		return nil
	}

	fullName := fmt.Sprintf("%s:%s", containingDir, name)
	fmt.Printf("\033[1mUpdating %s...\033[0m\n", fullName)

	var oldVer string
	jsonData, jsonErr := os.ReadFile(jsonPath)
	if jsonErr != nil {
		return errors.Join(jsonErr, fmt.Errorf("UpOne(): Failed to read `%s`", jsonPath))
	}
	switch kind {
	case UpFlake:
		rev, revErr := GetJsonObjectString(jsonData, "rev")
		if revErr != nil {
			return revErr
		}
		oldVer = rev
	case UpPkg:
		origVersion, origVersionErr := GetJsonObjectString(jsonData, "orig_version")
		if origVersionErr != nil {
			return origVersionErr
		}
		oldVer = origVersion
	}

	cmd := exec.Command(filepath.Join(scriptDir, name), oldVer)

	cmd.Env = append(cmd.Env, os.Environ()...)
	if *opts.force {
		cmd.Env = append(cmd.Env, "FORCE=1")
	} else {
		cmd.Env = append(cmd.Env, "FORCE=0")
	}

	// FIXME: Download processes are not displayed
	stdout, cmdErr := cmd.Output()
	if cmdErr != nil {
		if _, ok := cmdErr.(*exec.ExitError); !ok {
			return errors.Join(cmdErr, fmt.Errorf("UpOne(): Failed to run update script %s", fullName))
		}
	}

	exit := cmd.ProcessState.ExitCode()
	switch exit {
	case 0:
		if err := os.WriteFile(jsonPath, stdout, 0o644); err != nil {
			return errors.Join(err, fmt.Errorf("UpOne(): Failed to write to `%s`", jsonPath))
		}
	case 200:
		fmt.Println("Skipped")
	default:
		fmt.Fprint(os.Stderr, string(cmdErr.(*exec.ExitError).Stderr))
		return fmt.Errorf("UpOne(): Update script %s exited with status %d", fullName, exit)
	}

	return nil
}

func GetJsonObjectString(data []byte, key string) (value string, err error) {
	var rootAny map[string]any
	if err := json.Unmarshal(data, &rootAny); err != nil {
		return "", errors.Join(err, fmt.Errorf("UpOne(): Malformed JSON"))
	}
	val, valOk := rootAny[key].(string)
	if !valOk {
		return "", fmt.Errorf("UpOne(): Malformed output (val)")
	}

	return val, nil
}
