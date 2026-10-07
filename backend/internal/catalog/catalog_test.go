package catalog

import (
	"bytes"
	"image"
	"image/png"
	"os"
	"path/filepath"
	"testing"
)

func TestImageValidationAndOCRParser(t *testing.T) {
	t.Setenv("UPLOAD_DIR", t.TempDir())
	if _, err := storeImage([]byte("not an image")); err == nil {
		t.Fatal("invalid bytes accepted")
	}
	var small bytes.Buffer
	png.Encode(&small, image.NewRGBA(image.Rect(0, 0, 20, 20)))
	if _, err := storeImage(small.Bytes()); err == nil {
		t.Fatal("tiny image accepted")
	}
	raw, err := os.ReadFile("testdata/menu.png")
	if err != nil {
		t.Fatal(err)
	}
	saved, err := storeImage(raw)
	if err != nil {
		t.Fatal(err)
	}
	if _, err = os.Stat(filepath.Join(storageDir(), saved.Name)); err != nil {
		t.Fatal(err)
	}
	items := parseMenu("Coffee 35.000\nPeach Tea 45k\nLunch 55,5k\nnoise\nCoffee 35.000\n")
	if len(items) != 3 || items[0].Price != 35000 || items[1].Price != 45000 || items[2].Price != 55500 {
		t.Fatalf("bad parsed menu: %+v", items)
	}
	if validMenu([]menuDraft{{Name: "Coffee", Price: 35000}, {Name: "coffee", Price: 1}}) {
		t.Fatal("duplicate names accepted")
	}
}
