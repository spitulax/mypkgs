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
	"sync"
)

func Run(cmd string) error {
	c := exec.Command("sh", "-c", cmd)

	stdout, stdoutErr := c.StdoutPipe()
	if stdoutErr != nil {
		return errors.Join(stdoutErr, fmt.Errorf("Run(): Failed to get stdout"))
	}
	stderr, stderrErr := c.StderrPipe()
	if stderrErr != nil {
		return errors.Join(stderrErr, fmt.Errorf("Run(): Failed to get stderr"))
	}

	if err := c.Start(); err != nil {
		return errors.Join(err, fmt.Errorf("Run(): Failed to run `%s`", cmd))
	}
	pid := c.Process.Pid

	ReadOutput := func(wg *sync.WaitGroup, reader io.ReadCloser, output io.Writer) {
		defer wg.Done()

		var buf [1024]byte
		for {
			n, readErr := reader.Read(buf[:])
			if n > 0 && readErr == nil {
				fmt.Fprint(output, string(buf[:n]))
			} else {
				break
			}
		}
	}

	var wg sync.WaitGroup
	wg.Add(2)
	go ReadOutput(&wg, stdout, os.Stdout)
	go ReadOutput(&wg, stderr, os.Stderr)
	wg.Wait()

	if err := c.Wait(); err != nil {
		if exitErr, ok := err.(*exec.ExitError); ok {
			return fmt.Errorf("Run(): Process %d exited with status %d", pid, exitErr.ExitCode())
		} else {
			return errors.Join(err, fmt.Errorf("Run(): Failed to wait process %d", pid))
		}
	}

	return nil
}

func RunCapture(cmd string) (out []byte, err error) {
	c := exec.Command("sh", "-c", cmd)
	stdout, err := c.Output()
	pid := c.ProcessState.Pid()

	if err != nil {
		if exitErr, ok := err.(*exec.ExitError); ok {
			fmt.Fprint(os.Stderr, string(exitErr.Stderr))
			return nil, fmt.Errorf("RunCapture(): Process %d exited with status %d", pid, exitErr.ExitCode())
		} else {
			return nil, errors.Join(err, fmt.Errorf("RunCapture(): Failed to wait process %d", pid))
		}
	}

	return stdout, nil
}

const NixCmd = "nix --experimental-features 'nix-command flakes' --accept-flake-config"

func Nix(args string) error {
	return Run(NixCmd + " " + args)
}

func NixCapture(args string) (out []byte, err error) {
	return RunCapture(NixCmd + " " + args)
}

func Cachix(args string) error {
	return Run("cachix " + args)
}

func NewFlagSet(name string) *flag.FlagSet {
	return flag.NewFlagSet(name, flag.ExitOnError)
}

func FlagNom(f *flag.FlagSet) *bool {
	_, err := exec.LookPath("nom")
	hasNom := err == nil
	return f.Bool("nom", hasNom, "Whether to use nom")
}

func Paths() (paths []string, err error) {
	output, outputErr := NixCapture("path-info --json result/")
	if outputErr != nil {
		return nil, errors.Join(outputErr, fmt.Errorf("Paths(): Failed to get path info of `result/`"))
	}

	var root map[string]any
	if err := json.Unmarshal(output, &root); err != nil {
		return nil, errors.Join(err, fmt.Errorf("Paths(): Malformed JSON"))
	}

	for _, v := range root {
		p, pOk := v.(map[string]any)
		if !pOk {
			return nil, fmt.Errorf("Paths(): Malformed output (p)")
		}

		refsAny, refsAnyOk := p["references"].([]any)
		if !refsAnyOk {
			return nil, fmt.Errorf("Paths(): Malformed output (refsAny)")
		}

		for _, refAny := range refsAny {
			ref, refOk := refAny.(string)
			if !refOk {
				return nil, fmt.Errorf("Paths(): Malformed output (ref)")
			}
			paths = append(paths, ref)
		}
	}

	return paths, nil
}

// Assuming `dst` exists
// `newName` is emptiable
func CopyToDir(dst string, src string, newName string) error {
	srcF, srcFErr := os.Open(src)
	if srcFErr != nil {
		return errors.Join(srcFErr, fmt.Errorf("CopyToDir(): Failed to open `%s`", src))
	}
	defer srcF.Close()

	dstFilePath := dst
	if newName == "" {
		dstFilePath = filepath.Join(dstFilePath, filepath.Base(src))
	} else {
		dstFilePath = filepath.Join(dstFilePath, newName)
	}

	// Would override files
	dstF, dstFErr := os.Create(dstFilePath)
	if dstFErr != nil {
		return errors.Join(dstFErr)
	}
	defer dstF.Close()

	srcContent, srcReadErr := io.ReadAll(srcF)
	if srcReadErr != nil {
		return errors.Join(srcReadErr, fmt.Errorf("CopyToDir(): Failed to read `%s`", src))
	}

	dstWritten, dstWriteErr := dstF.Write(srcContent)
	if dstWriteErr != nil {
		return errors.Join(srcReadErr, fmt.Errorf("CopyToDir(): Failed to write to `%s`", dstFilePath))
	}
	if dstWritten != len(srcContent) {
		return fmt.Errorf("CopyToDir(): Corrupt copy from `%s` to `%s`", src, dstFilePath)
	}

	return nil
}
