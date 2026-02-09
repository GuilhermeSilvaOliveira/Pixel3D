/*  AVISO: Este codigo nao foi desenvolvido por mim, so contem alteracoes de minha autoria para se adequar ao meu projeto.
    Todos os direitos e creditos sao de Alexander Ameye, voce pode ver o artigo do autor original(https://ameye.dev/notes/edge-detection-outlines/) 
    
    NOTICE: This code was not developed by me, it only contains modifications of my own making to suit my project.
    All rights and credits belong to Alexander Ameye, you can see the original author's article (https://ameye.dev/notes/edge-detection-outlines/)
*/
using System;
using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

public class EdgeDetection : ScriptableRendererFeature
{
    private class EdgeDetectionPass : ScriptableRenderPass
    {
        private Material material;

        private static readonly int OutlineThicknessProperty = Shader.PropertyToID("_OutlineThickness");
        private static readonly int OutlineColorProperty = Shader.PropertyToID("_OutlineColor");
        private static readonly int ReferenceResolution = Shader.PropertyToID("_Resolution");
        private static readonly int UseObjectColorProperty = Shader.PropertyToID("_UseObjectColor");

        public EdgeDetectionPass()
        {
            profilingSampler = new ProfilingSampler(nameof(EdgeDetectionPass));
        }

        public void Setup(ref EdgeDetectionSettings settings, ref Material edgeDetectionMaterial)
        {
            material = edgeDetectionMaterial;
            renderPassEvent = settings.renderPassEvent;

            material.SetFloat(OutlineThicknessProperty, settings.outlineThickness);
            material.SetColor(OutlineColorProperty, settings.outlineColor);
            material.SetVector(ReferenceResolution, settings.referenceResolution);

            material.SetFloat(UseObjectColorProperty, settings.useObjectColor ? 1.0f : 0.0f);
        }

        public override void Execute(ScriptableRenderContext context, ref RenderingData renderingData)
        {
            var outlineCmd = CommandBufferPool.Get();

            using (new ProfilingScope(outlineCmd, profilingSampler))
            {
               
                CoreUtils.SetRenderTarget(outlineCmd, renderingData.cameraData.renderer.cameraColorTargetHandle);
                context.ExecuteCommandBuffer(outlineCmd);
                outlineCmd.Clear();

                Blitter.BlitTexture(outlineCmd, Vector2.one, material, 0);
            }

            context.ExecuteCommandBuffer(outlineCmd);
            CommandBufferPool.Release(outlineCmd);
        }
    }

    [Serializable]
    public class EdgeDetectionSettings
    {
        public RenderPassEvent renderPassEvent = RenderPassEvent.AfterRenderingTransparents;

        [Header("Settings")]
        [Range(0, 15)] public int outlineThickness = 3;
        public Vector4 referenceResolution = new Vector4(1920, 1080, 0, 0);

        [Header("Color")]
        public bool useObjectColor = false;
        public Color outlineColor = Color.black;
    }

    [SerializeField] private EdgeDetectionSettings settings = new EdgeDetectionSettings();
    private Material edgeDetectionMaterial;
    private EdgeDetectionPass edgeDetectionPass;

    public override void Create()
    {
        edgeDetectionPass ??= new EdgeDetectionPass();
    }

    public override void AddRenderPasses(ScriptableRenderer renderer, ref RenderingData renderingData)
    {
        if (renderingData.cameraData.cameraType is CameraType.Preview or CameraType.Reflection) return;

        if (edgeDetectionMaterial == null)
        {
            
            edgeDetectionMaterial = CoreUtils.CreateEngineMaterial(Shader.Find("Hidden/Edge Detection"));
            if (edgeDetectionMaterial == null)
            {
                Debug.LogWarning("Material de Edge Detection não encontrado.");
                return;
            }
        }

        
        edgeDetectionPass.ConfigureInput(ScriptableRenderPassInput.Depth | ScriptableRenderPassInput.Normal | ScriptableRenderPassInput.Color);
        edgeDetectionPass.Setup(ref settings, ref edgeDetectionMaterial);

        renderer.EnqueuePass(edgeDetectionPass);
    }

    protected override void Dispose(bool disposing)
    {
        CoreUtils.Destroy(edgeDetectionMaterial);
    }
}