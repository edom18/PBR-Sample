Shader "Custom/CookTorrance" {
	Properties {
		_Color ("Diffuse Color", Color) = (1,1,1,1)
		_MainTex ("Main Tex", 2D) = "white" {}
		_Roughness ("Roughness", Float) = 0.5
		_FresnelReflectance ("Fresnel Reflectance", Float) = 0.5
	}
	SubShader {
		Pass {
			Tags { "LightMode" = "ForwardBase" }
			
			CGPROGRAM
	        #include "UnityCG.cginc"
			#include "Lighting.cginc"

	        uniform float4 _Color;
			uniform float4 _MainTex_ST;
	        uniform float _Roughness;
	        uniform float _FresnelReflectance;
			uniform sampler2D _MainTex;
	        
			struct appdata {
				float4 vertex : POSITION;
				float3 normal : NORMAL;
				float2 uv : TEXCOORD0;
			};

			struct v2f {
				float4 pos : SV_POSITION;
				float2 uv : TEXCOORD0;
				float3 normal : TEXCOORD1;
				float4 vpos : TEXCOORD2;
			};

			#pragma vertex vert
			#pragma fragment frag

	        v2f vert(appdata v) {	            
				v2f o;
				o.pos = mul(UNITY_MATRIX_MVP, v.vertex);
				o.uv = TRANSFORM_TEX(v.uv, _MainTex);

				o.normal = normalize(mul(_Object2World, float4(v.normal, 0.0)).xyz);
				o.vpos = mul(_Object2World, v.vertex);

				return o;
	        }

	        float4 frag(v2f i) : COLOR {
	        	float3 ambientLight = unity_AmbientEquator.xyz * float3(_Color.rgb);
	        
				float3 lightDirectionNormal = normalize(_WorldSpaceLightPos0.xyz);
				float NdotL = saturate(dot(i.normal, lightDirectionNormal));

			   	float3 viewDirectionNormal = normalize((float4(_WorldSpaceCameraPos, 1.0) - i.vpos).xyz);
			   	float NdotV = saturate(dot(i.normal, viewDirectionNormal));

			    float3 halfVector = normalize(lightDirectionNormal + viewDirectionNormal);
			    float NdotH = saturate(dot(i.normal, halfVector));
			    float VdotH = saturate(dot(viewDirectionNormal, halfVector));

				float roughness = saturate(_Roughness);
			    float alpha = roughness * roughness;
			    float alpha2 = alpha * alpha;
				float t = ((NdotH * NdotH) * (alpha2 - 1.0) + 1.0);
				float PI = 3.1415926535897;
				float D = alpha2 / (PI * t * t);

			    float F0 = saturate(_FresnelReflectance);
			    float F = pow(1.0 - VdotH, 5.0);
			    F *= (1.0 - F0);
			    F += F0;

			    float NH2 = 2.0 * NdotH;
			    float g1 = (NH2 * NdotV) / VdotH;
			    float g2 = (NH2 * NdotL) / VdotH;
			    float G = min(1.0, min(g1, g2));

			    float specularReflection = (D * F * G) / (4.0 * NdotV * NdotL + 0.000001);
				float3 diffuseReflection = _LightColor0.xyz * _Color.xyz * NdotL;

			    return float4(ambientLight + diffuseReflection + specularReflection, 1.0);
	        }

	        ENDCG
         }
	} 
	//FallBack "Diffuse"
}
