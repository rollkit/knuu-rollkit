package main

import (
	"github.com/celestiaorg/knuu/pkg/knuu"
	//"github.com/stretchr/testify/assert"
	//"os"
	"testing"
)

func TestGM(t *testing.T) {
	t.Parallel()
	instance, err := knuu.NewInstance("alpine")
	if err != nil {
		t.Fatalf("Error creating instance '%v':", err)
	}
	err = instance.SetImage("docker.io/alpine:latest")
	if err != nil {
		t.Fatalf("Error setting image: %v", err)
	}

}
