Shader "Pixel3D/PixelSnap"
{
    Properties
    {
        _MainTex("Albedo", 2D) = "white" {}
        _NormalMap("Normal Map", 2D) = "bump" {}
        _Color("Tint Color", Color) = (1,1,1,1)
        _ShadowColor("Shadown Color",Color) = (0,0,0,1)
        
        _Smoothness("Smoothness", Range(0,10)) = 0.5
        _SmoothShine("Smoothness Shine",Range(0.5,64)) =64
        _SpecColor("Specular Color", Color) = (1,1,1,1)

        [Space(10)]
        _ShadeSteps("Shade Steps", Range(2, 10)) = 4
        _ShadeStepAdditionalLights("Shade Steps AdditionalLights", Range(2,10)) = 4

        [Space(10)]
        _OutlineColor("Outlie Color",Color)=(0,0,0,1)
        _OutlineThickness("Outline Thicness",float) = 0.09

        [Space(10)]
        _LightCutoff("Light Cutoff", Range(0,1)) = 0.3
    }

    SubShader
    {
        Tags { "RenderType"="Opaque" "RenderPipeline"="UniversalPipeline" }
        

         Pass
        {
            Stencil {
                    Ref 1
                    Comp NotEqual
                }
             Name "Outline"
             Tags { "LightMode" = "SRPDefaultUnlit" }
             Cull Front
             ZWrite On
             ZTest LEqual

             HLSLPROGRAM
             #pragma vertex vert
             #pragma fragment fragOutline
             #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

             float _OutlineThickness;
             float4 _OutlineColor;
             float2 _PixelResolution;

             struct Attributes
             {

                 float4 positionOS : POSITION;
                 float3 normalOS   : NORMAL;
                 float4 tangentOS  : TANGENT;
                 UNITY_VERTEX_INPUT_INSTANCE_ID
             };

             struct Varyings
             {
                 float4 positionCS : SV_POSITION;
                 UNITY_VERTEX_OUTPUT_STEREO
             };

             Varyings vert(Attributes IN)
             {
                 Varyings OUT;
                 UNITY_SETUP_INSTANCE_ID(IN);
                 UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(OUT);
                
                 VertexNormalInputs   ninput = GetVertexNormalInputs(IN.normalOS, IN.tangentOS);
                 VertexPositionInputs vpos = GetVertexPositionInputs(IN.positionOS.xyz);

                 //IN.normalOS.xyz += normalize(IN.normalOS.xyz) * _OutlineThickness;
                 IN.positionOS.xyz += normalize(IN.positionOS.xyz) * _OutlineThickness /5;
                 

                 OUT.positionCS = TransformObjectToHClip(IN.positionOS.xyz);
                
                 //IN.normalOS += IN.positionOS.xyz *1;

                 float3 normOS = normalize(IN.positionOS);

                 //IN.positionOS.y -= 0.1;
           
                 OUT.positionCS = TransformWorldToHClip(IN.positionOS.xyz);

                 if(_PixelResolution.x < 1 || _PixelResolution.y < 1){
                    _PixelResolution = _ScreenParams.xy;
                    }

                 float3 offset = normOS * _OutlineThickness *20;
                 float3 displacedPosOS = IN.positionOS.xyz ;

                 float3 worldPos = TransformObjectToWorld(displacedPosOS);
                 float4 clipPos = TransformWorldToHClip(worldPos);

                 float3 worldCenter = TransformObjectToWorld(float3(0, 0, 0));
                 float4 centerClipPos = TransformWorldToHClip(worldCenter);
                 float2 screenCenter = (centerClipPos.xy / centerClipPos.w) * _ScreenParams.xy * 0.5;
                 float2 pixelSize = _ScreenParams.xy / _PixelResolution;
                 float2 snapped = floor((screenCenter / pixelSize) + 0.5) * pixelSize;
                 float2 screenOffset = snapped - screenCenter;
                 float2 offsetClip = (screenOffset / (_ScreenParams.xy * 0.5)) * clipPos.w;
                 clipPos.xy += offsetClip;

                 OUT.positionCS = clipPos;
                 
                 return OUT;
             }

             half4 fragOutline(Varyings IN) : SV_Target
             {
                 return _OutlineColor;
             }
             ENDHLSL
        }

        Pass
        {
            Name "ForwardLit"
            Tags { "LightMode" = "UniversalForward" "Queue" = "Geometry" }
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS _MAIN_LIGHT_SHADOWS_CASCADE _MAIN_LIGHT_SHADOWS_SCREEN
            #pragma multi_compile _ _ADDITIONAL_LIGHTS
            #pragma multi_compile _ _SHADOWS_SOFT
            #pragma multi_compile_fragment _ _ADDITIONAL_LIGHT_SHADOWS
            //#pragma enable_d3d11_debug_symbols

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/SurfaceInput.hlsl"

            sampler2D _MainTex;
            float4 _MainTex_ST;
            sampler2D _NormalMap;
            float4 _NormalMap_ST;

            float2 _PixelResolution;
            float4 _Color;
            float4 _ShadowColor;
            float4 _SpecColor;
            float _Smoothness;
            float _SmoothShine;
            float _ShadeSteps;
            float _ShadeStepAdditionalLights;

            float _LightCutoff;

            struct Attributes
            {
                float4 positionOS : POSITION;
                float2 uv         : TEXCOORD0;
                float3 normalOS   : NORMAL;
                float4 tangentOS  : TANGENT;
            };

            struct Varyings
            {
                float4 positionCS  : SV_POSITION;
                float2 uv          : TEXCOORD0;
                float3 positionWS  : TEXCOORD1;
                float3 normalWS    : TEXCOORD2;
                float3 tangentWS   : TEXCOORD3;
                float3 bitangentWS : TEXCOORD4;
            };

            Varyings vert(Attributes IN)
            {
                Varyings OUT;
                VertexPositionInputs vpos = GetVertexPositionInputs(IN.positionOS.xyz);
                VertexNormalInputs   ninput = GetVertexNormalInputs(IN.normalOS, IN.tangentOS);

                if(_PixelResolution.x < 1 || _PixelResolution.y < 1){
                    _PixelResolution = _ScreenParams.xy;
                    }

                //Pixel snapping
                float4 clipPos = vpos.positionCS;
                //posicao central(pivot) do objeto no mundo e no clip-space
                //central position(pivot) of the object in the world and in clip-space
                float3 worldCenter = TransformObjectToWorld(float3(0, 0, 0));
                float4 centerClipPos = TransformWorldToHClip(worldCenter);

                
                //converte a posição do centro(pivot) do espaço de recorte para coordenadas de pixel centradas na tela
                //converts the position of the center(pivot) of the clipping space to pixel coordinates centered on the screen
                float2 screenCenter = (centerClipPos.xy / centerClipPos.w) * _ScreenParams.xy * 0.5;

                //define tamanho do pixel em tela
                //define pixel size on screen
                float2 pixelSize = _ScreenParams.xy / _PixelResolution;

                //realiza o snap na posicao central do objeto
                //performs the snap to the center position of the object
                float2 snapped = floor((screenCenter / pixelSize) + 0.5) * pixelSize;
                float2 screenOffset = snapped - screenCenter;

                //converte e de volta para clip space
                //converts and back to clip space
                float2 offsetClip = (screenOffset / (_ScreenParams.xy * 0.5)) * centerClipPos.w;
                clipPos.xy += offsetClip.xy;

                OUT.positionCS = clipPos;
                OUT.uv         = TRANSFORM_TEX(IN.uv, _MainTex);
                OUT.positionWS = vpos.positionWS;
                OUT.normalWS   = ninput.normalWS;
                OUT.tangentWS  = ninput.tangentWS;
                OUT.bitangentWS= ninput.bitangentWS;
                return OUT;
            }

            half4 frag(Varyings IN) : SV_Target
            {
                //Base color and normal
                float3 albedo = tex2D(_MainTex, IN.uv).rgb * _Color.rgb;
                float3 normalTS = UnpackNormal(tex2D(_NormalMap, IN.uv));
                float3x3 TBN = float3x3(IN.tangentWS, IN.bitangentWS, IN.normalWS);
                float3 normalWS = normalize(mul(normalTS, TBN));
                float3 viewDir = normalize(_WorldSpaceCameraPos - IN.positionWS);

                //Shadow coordinates
                float4 shadowCoord = TransformWorldToShadowCoord(IN.positionWS);

                //Main light with shadows
                Light mainLight = GetMainLight(shadowCoord);
                float3 lightDir = normalize(mainLight.direction);
                float NdotL = saturate(dot(normalWS, lightDir));


                float lightThreshold = step(_LightCutoff,NdotL);

                float toonDiffuseMain = floor(NdotL * _ShadeSteps) / (_ShadeSteps - 1.0 );
                toonDiffuseMain *= lightThreshold;
                float lightIntesity = toonDiffuseMain * mainLight.shadowAttenuation;

                float3 litColor = albedo * lightIntesity;
                float3 shadownColor = albedo * _ShadowColor.rgb;
                float3 diffuse =  lerp(shadownColor,litColor,lightIntesity);

                //float3 diffuse = albedo * mainLight.color * toonDiffuseMain  * mainLight.shadowAttenuation;

                //Specular shading Blinn-Phong
                float3 halfwayDir = normalize(viewDir + lightDir);
                float spec = pow(saturate(dot(normalWS, halfwayDir)), _SmoothShine) * _Smoothness;
                float toonSpecMain = floor(spec * _ShadeSteps) / (_ShadeSteps - 1.0);
                float3 specular = _SpecColor.rgb * toonSpecMain * mainLight.shadowAttenuation;

                //Ambient lighting
                float3 ambient = SampleSH(normalWS) * albedo;

                //Additional lights with shadows
                uint lightCount = GetAdditionalLightsCount();
                for (uint i = 0; i < lightCount; ++i)
                {
                    Light light = GetAdditionalLight(i, IN.positionWS);
                    float3 ldir = normalize(light.direction);
                    float atten = light.distanceAttenuation * light.shadowAttenuation;
                    float diff = saturate(dot(normalWS, ldir));
                    float lightThreshold = step(_LightCutoff,diff);
                    float toonDiff = floor(diff * _ShadeStepAdditionalLights) / (_ShadeStepAdditionalLights - 1.0);
                    diffuse += albedo * light.color * toonDiff * atten * lightThreshold;

                    float3 h = normalize(ldir + viewDir);
                    float s = pow(saturate(dot(normalWS, h)), _SmoothShine) * _Smoothness;
                    float toonSpec = floor(s * _ShadeStepAdditionalLights) / (_ShadeStepAdditionalLights - 1.0);
                    specular += _SpecColor.rgb * toonSpec * atten;
                }

                float3 finalColor = diffuse + specular + ambient ;
                return float4(finalColor, 1.0);
            }
            ENDHLSL
        }

         
        Pass
        {
            Name "ShadowCaster"
            Tags { "LightMode" = "ShadowCaster" }
            HLSLPROGRAM
            #pragma target 2.0
            #pragma vertex vertShadow
            #pragma fragment fragShadow
            #pragma multi_compile_shadowcaster
            #pragma multi_compile_instancing
           
            //#include "UnityCG.cginc"

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/SurfaceInput.hlsl"

            float2 _PixelResolution;
            struct Attributes { float4 positionOS : POSITION; float2 uv : TEXCOORD0; float3 normalOS : NORMAL; };
            struct ShadowVaryings { float4 positionCS : SV_POSITION; };

            ShadowVaryings vertShadow(Attributes IN)
            {
                ShadowVaryings OUT;
                VertexPositionInputs vertexInput = GetVertexPositionInputs(IN.positionOS.xyz);
                float4 clipPos = vertexInput.positionCS;
                //float shadowMapResolution = 1024; // URP fornece isso

                //float2 pixelSize = 2 / shadowMapResolution;

                //float2 ndc = clipPos.xy / clipPos.w;
                //ndc = floor(ndc / pixelSize + 0.5) * pixelSize;
                //clipPos.xy = ndc * clipPos.w;

                OUT.positionCS = clipPos;
                return OUT;
            }

            half fragShadow(ShadowVaryings IN) : SV_Target
            {
                return IN.positionCS;
            }
            
            ENDHLSL
        }

        Pass
        {
            Name "DepthNormals"
            Tags{"LightMode" = "DepthNormals"}
            ZWrite On

            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            float2 _PixelResolution;

            struct Attributes
            {
                float4 positionOS : POSITION;
                float3 normalOS   : NORMAL;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            struct Varyings
            {
                float4 positionCS : SV_POSITION;
                float3 normalWS   : TEXCOORD0;
                UNITY_VERTEX_OUTPUT_STEREO
            };

            Varyings vert(Attributes IN)
            {
                Varyings OUT;
                UNITY_SETUP_INSTANCE_ID(IN);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(OUT);

                float3 worldPos = TransformObjectToWorld(IN.positionOS.xyz);
                float4 clipPos = TransformWorldToHClip(worldPos);

                if(_PixelResolution.x < 1 || _PixelResolution.y < 1){
                    _PixelResolution = _ScreenParams.xy;
                    }

                float3 worldCenter = TransformObjectToWorld(float3(0, 0, 0));
                float4 centerClipPos = TransformWorldToHClip(worldCenter);
         
                float2 screenCenter = (centerClipPos.xy / centerClipPos.w) * _ScreenParams.xy * 0.5;
                float2 pixelSize = _ScreenParams.xy / _PixelResolution;
                float2 snapped = floor((screenCenter / pixelSize) + 0.5) * pixelSize;
                float2 screenOffset = snapped - screenCenter;
                float2 offsetClip = (screenOffset / (_ScreenParams.xy * 0.5)) * centerClipPos.w;
                
                clipPos.xy += offsetClip;

                OUT.positionCS = clipPos;
                OUT.normalWS = TransformObjectToWorldNormal(IN.normalOS);
                return OUT;
            }

            float4 frag(Varyings IN) : SV_Target
            {
                return float4(PackNormalOctRectEncode(TransformWorldToViewNormal(IN.normalWS, true)), 0.0, 0.0);
            }
            ENDHLSL
        }
    }
    FallBack "Universal Forward"
}
