/*  AVISO: Este codigo nao foi desenvolvido por mim, so contem alteracoes de minha autoria para se adequar ao meu projeto.
    Todos os direitos e creditos sao de Alexander Ameye, voce pode ver o artigo do autor original(https://ameye.dev/notes/edge-detection-outlines/) 
    
    NOTICE: This code was not developed by me, it only contains modifications of my own making to suit my project.
    All rights and credits belong to Alexander Ameye, you can see the original author's article (https://ameye.dev/notes/edge-detection-outlines/)
*/
Shader "Hidden/Edge Detection"
{
    Properties
    {
        _MainTex ("Base (RGB)", 2D) = "white" {}
        _OutlineThickness ("Outline Thickness", Float) = 1
        _OutlineColor ("Outline Color", Color) = (0, 0, 0, 1)
        _Resolution("Screen Resolution",Vector) = (1920,1080,0)
        _UseObjectColor ("Use Object Color", Float) = 0
    }

    SubShader
    {
        Tags
        {
            "RenderPipeline" = "UniversalPipeline"
            "RenderType"="Opaque"
        }

        ZWrite Off
        Cull Off
        Blend SrcAlpha OneMinusSrcAlpha

        Pass 
        {
            Name "EDGE DETECTION OUTLINE"
            
            HLSLPROGRAM
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.core/Runtime/Utilities/Blit.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DeclareDepthTexture.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DeclareNormalsTexture.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DeclareOpaqueTexture.hlsl" 

            sampler2D _MainTex;
            float _OutlineThickness;
            float4 _OutlineColor;
            float4 _Resolution;
            float _UseObjectColor;

            #pragma vertex Vert 
            #pragma fragment frag

            struct appdata {
                float4 vertex : POSITION;
            };

            struct v2f {
                float4 vertex : SV_POSITION;
                float2 uv : TEXCOORD0;
            };

            v2f vert (appdata v) {
                v2f o;
                o.uv = o.vertex.xy * 0.5 + 0.5;
                return o;
            }

            float RobertsCross(float3 samples[4])
            {
                const float3 difference_1 = samples[1] - samples[2];
                const float3 difference_2 = samples[0] - samples[3];
                return sqrt(dot(difference_1, difference_1) + dot(difference_2, difference_2));
            }

            float RobertsCross(float samples[4])
            {
                const float difference_1 = samples[1] - samples[2];
                const float difference_2 = samples[0] - samples[3];
                return sqrt(difference_1 * difference_1 + difference_2 * difference_2);
            }
            
            float3 SampleSceneNormalsRemapped(float2 uv)
            {
                return SampleSceneNormals(uv) * 0.5 + 0.5;
            }

            float SampleSceneLuminance(float2 uv)
            {
                float3 color = SampleSceneColor(uv);
                return color.r * 0.3 + color.g * 0.59 + color.b * 0.11;
            }

            half4 frag(Varyings IN) : SV_TARGET
            {
                float2 uv = IN.texcoord;
                float2 texel_size = float2(1.0 / _Resolution.x, 1.0 / _Resolution.y);
                
                const float half_width_f = floor(_OutlineThickness * 0.5);
                const float half_width_c = ceil(_OutlineThickness * 0.5);
                float halfWidth =  _OutlineThickness * 0.5;

                float2 uvs[4];
                uvs[0] = uv + texel_size * float2(half_width_f, half_width_c) * float2(-1, 1);  // top left
                uvs[1] = uv + texel_size * float2(half_width_c, half_width_c) * float2(1, 1);   // top right
                uvs[2] = uv + texel_size * float2(half_width_f, half_width_f) * float2(-1, -1); // bottom left
                uvs[3] = uv + texel_size * float2(half_width_c, half_width_f) * float2(1, -1);  // bottom right             
                
                float3 normal_samples[4];
                float depth_samples[4], luminance_samples[4];
                

                for (int i = 0; i < 4; i++) {
                    depth_samples[i] = SampleSceneDepth(uvs[i]);
                    normal_samples[i] = SampleSceneNormalsRemapped(uvs[i]);
                    luminance_samples[i] = SampleSceneLuminance(uvs[i]);
                }
                
                float edge_depth = RobertsCross(depth_samples);
                float edge_normal = RobertsCross(normal_samples);
                float edge_luminance = RobertsCross(luminance_samples);

                float depth_threshold = 0.5 / 200.0f;
                edge_depth = edge_depth > depth_threshold ? 1 : 0;
                
                
                float normal_threshold = 1 / 4.0f;
                edge_normal = edge_normal > normal_threshold ? 1 : 0;
                
                float luminance_threshold = 1 / 0.5f;
                edge_luminance = edge_luminance > luminance_threshold ? 1 : 0;
                
                float edge = max(edge_depth, max(edge_normal, edge_luminance));

                float centerDepthRaw = SampleSceneDepth(uv);
                bool isBackgroundPixel = false;
                
                //limite de tolerancia no modo ortográfico o depth varia de 0 a 1 entre o near e far plane.
                //0.001 é um bom valor se seus planos de corte (clipping planes) nao estiverem absurdamente distantes.

                //The tolerance limit in orthographic mode is 0 to 1 between the near and far plane.
                //0.001 is a good value if your clipping planes are not absurdly far apart.
                float orthoThreshold = 0.001; 

                //verifica cada vizinho
                //checks each neighbor
                for(int j=0; j<4; j++) {
                    float neighborDepthRaw = depth_samples[j];
                    
                    //UNITY_REVERSED_Z é definido em directX
                    //nesses casos 1.0 é perto (near) 0.0 é longe (far)

                    //UNITY_REVERSED_Z is defined in DirectX
                    //in these cases 1.0 is near and 0.0 is far
                    #if UNITY_REVERSED_Z
                        //se o centro for menor que o vizinho ele está mais "perto do zero" (mais longe da camera)

                        //If the center is smaller than its neighbor, it is "closer to zero" (further from the camera)
                        if(centerDepthRaw < neighborDepthRaw - orthoThreshold) {
                            isBackgroundPixel = true;
                            break;
                        }
                    #else
                        //openGL e outros: 0.0 é perto (Near) 1.0 é longe (Far)
                        //se o centro for maior que o vizinho ele está mais longe

                        //OpenGL and others: 0.0 is near, 1.0 is far
                        //If the center is larger than its neighbor, it is farther away
                        if(centerDepthRaw > neighborDepthRaw + orthoThreshold) {
                            isBackgroundPixel = true;
                            break;
                        }
                    #endif
                }
                //se for pixel de fundo encerramos a borda aqui
                //If it's a background pixel, we end the border here.
                if(isBackgroundPixel)
                { 
                    edge = 0;
                }
                
                float4 finalColor = _OutlineColor;

                if (_UseObjectColor > 0)
                {
                    //amostra a cor original da cena neste pixel
                    //Samples the original color of the scene in this pixel
                    float3 sceneColor = SampleSceneColor(uv);
                    
                    //pode deixar a cor mais escura ou mais clara para o contorno aparecer bem  finalColor = float4(sceneColor * 0.5, 1) 50% mais escuro
                    //You can make the color darker or lighter so the outline shows up well. finalColor = float4(sceneColor * 0.5, 1) 50% darker
                    finalColor = float4(sceneColor *0.3, 1) * _OutlineColor.w; 
                }

                return edge * finalColor;
            }
            ENDHLSL
        }
    }
}