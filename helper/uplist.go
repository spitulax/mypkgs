package main

import (
	"encoding/json"
	"errors"
	"fmt"
)

func Uplist() error {
	fmt.Println("\033[1mUpdating package list...\033[0m")

	var path string
	out, outErr := NixCapture("build .#mypkgs-list --json")
	if outErr != nil {
		return errors.Join(outErr, fmt.Errorf("Uplist(): Failed to build `mypkgs-list`"))
	}

	var root [](map[string]any)
	if err := json.Unmarshal(out, &root); err != nil {
		return errors.Join(err, fmt.Errorf("Uplist(): Malformed JSON"))
	}

	for _, p := range root {
		pathsAny, pathsAnyOk := p["outputs"].(map[string]any)
		if !pathsAnyOk {
			return fmt.Errorf("Uplist(): Malformed output (pathsAny)")
		}

		var pathOk bool
		path, pathOk = pathsAny["out"].(string)
		if !pathOk {
			return fmt.Errorf("Uplist(): Malformed output (path)")
		}
	}

	if err := CopyToDir(".", path, "list.md"); err != nil {
		return errors.Join(err, fmt.Errorf("Uplist(): Failed to copy list"))
	}

	return nil
}
