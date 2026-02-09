using System.Collections;
using System.Collections.Generic;
using TMPro;
using UnityEngine;
using UnityEngine.UI;

public class CamUI : MonoBehaviour
{
    [Header("Reference")]
    public PixelPerfect3D pixelCam;

    [Header("Resolution UI")]
    public TMP_InputField widthInput;
    public TMP_InputField heightInput;

    [Header("Color Steps UI")]
    public Slider rSlider;
    public Slider gSlider;
    public Slider bSlider;
    public TMP_Text rText;
    public TMP_Text gText;
    public TMP_Text bText;

    void Start()
    {

        widthInput.text = pixelCam.resolution.x.ToString();
        heightInput.text = pixelCam.resolution.y.ToString();

        rSlider.value = pixelCam.ColorSteps.x;
        gSlider.value = pixelCam.ColorSteps.y;
        bSlider.value = pixelCam.ColorSteps.z;
    }

   
    public void ApplyResolution()
    {
        int width = int.Parse(widthInput.text);
        int height = int.Parse(heightInput.text);

        pixelCam.resolution = new Vector2Int(width, height);
        pixelCam.GenerateTexture(pixelCam.resolution);
    }

    
    public void UpdateColorSteps()
    {
        pixelCam.ColorSteps = new Vector3Int(
            Mathf.RoundToInt(rSlider.value),
            Mathf.RoundToInt(gSlider.value),
            Mathf.RoundToInt(bSlider.value)
        );
        rText.SetText(rSlider.value.ToString());
        gText.SetText(gSlider.value.ToString());
        bText.SetText(bSlider.value.ToString());
    }
}
