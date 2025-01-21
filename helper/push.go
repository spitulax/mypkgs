package main

import (
	"errors"
	"fmt"
	"strings"
)

func Push(cachixName string) error {
	fmt.Println("\033[1mPushing packages...\033[0m")

	paths, pathsErr := Paths()
	if pathsErr != nil {
		return pathsErr
	}
	pathsJoined := strings.Join(paths, " ")

	if err := Cachix("push '" + cachixName + "' " + pathsJoined); err != nil {
		return errors.Join(err, fmt.Errorf("Push(): Failed to run cachix"))
	}

	return nil
}
