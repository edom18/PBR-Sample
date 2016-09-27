Shader "Custom/CookTorrance" {
	Properties {
		_Color ("Diffuse Color", Color) = (1,1,1,1)
		_Roughness ("Roughness", Float) = 0.5
		_FresnelReflectance ("Fresnel Reflectance", Float) = 0.5
	}
	SubShader {
		Pass {
			Tags { "LightMode" = "ForwardBase" }
			
			CGPROGRAM
			#include "Lighting.cginc"

	        uniform float4 _Color;
	        uniform float _Roughness;
	        uniform float _FresnelReflectance;
	        
			struct appdata {
				float4 vertex : POSITION;
				float3 normal : NORMAL;
			};

			struct v2f {
				float4 pos : SV_POSITION;
				float3 normal : TEXCOORD1;
				float4 vpos : TEXCOORD2;
			};

			#pragma vertex vert
			#pragma fragment frag

			// D（GGX）の項
			float D_GGX(float3 H, float3 N) {
				float NdotH = saturate(dot(H, N));
				float roughness = saturate(_Roughness);
			    float alpha = roughness * roughness;
			    float alpha2 = alpha * alpha;
				float t = ((NdotH * NdotH) * (alpha2 - 1.0) + 1.0);
				float PI = 3.1415926535897;
				return alpha2 / (PI * t * t);
			}

			// フレネルの項
			float Flesnel(float3 V, float3 H) {
				float VdotH = saturate(dot(V, H));
			    float F0 = saturate(_FresnelReflectance);
			    float F = pow(1.0 - VdotH, 5.0);
			    F *= (1.0 - F0);
			    F += F0;
				return F;
			}

			// G - 幾何減衰の項（クック トランスモデル）
			float G_CookTorrance(float3 L, float3 V, float3 H, float3 N) {
				float NdotH = saturate(dot(N, H));
				float NdotL = saturate(dot(N, L));
				float NdotV = saturate(dot(N, V));
				float VdotH = saturate(dot(V, H));

			    float NH2 = 2.0 * NdotH;
			    float g1 = (NH2 * NdotV) / VdotH;
			    float g2 = (NH2 * NdotL) / VdotH;
			    float G = min(1.0, min(g1, g2));
				return G;
			}


	        v2f vert(appdata v) {	            
				v2f o;
				o.pos = mul(UNITY_MATRIX_MVP, v.vertex);

				// ワールド空間での法線を計算
				o.normal = normalize(mul(_Object2World, float4(v.normal, 0.0)).xyz);

				// 該当ピクセルのライティングに、ワールド空間上での位置を保持しておく
				o.vpos = mul(_Object2World, v.vertex);

				return o;
	        }

	        float4 frag(v2f i) : COLOR {
				// 環境光とマテリアルの色を合算
	        	float3 ambientLight = unity_AmbientEquator.xyz * _Color.rgb;
	        
				// ワールド空間上のライト位置と法線との内積を計算
				float3 lightDirectionNormal = normalize(_WorldSpaceLightPos0.xyz);
				float NdotL = saturate(dot(i.normal, lightDirectionNormal));

				// ワールド空間上の視点（カメラ）位置と法線との内積を計算
			   	float3 viewDirectionNormal = normalize((float4(_WorldSpaceCameraPos, 1.0) - i.vpos).xyz);
			   	float NdotV = saturate(dot(i.normal, viewDirectionNormal));

				// ライトと視点ベクトルのハーフベクトルを計算
			    float3 halfVector = normalize(lightDirectionNormal + viewDirectionNormal);

				// D_GGXの項
				float D = D_GGX(halfVector, i.normal);

				// Fの項
				float F = Flesnel(viewDirectionNormal, halfVector);

				// Gの項
				float G = G_CookTorrance(lightDirectionNormal, viewDirectionNormal, halfVector, i.normal);

				// スペキュラおよびディフューズを計算
			    float specularReflection = (D * F * G) / (4.0 * NdotV * NdotL + 0.000001);
				float3 diffuseReflection = _LightColor0.xyz * _Color.xyz * NdotL;

				// 最後に色を合算して出力
			    return float4(ambientLight + diffuseReflection + specularReflection, 1.0);
	        }

	        ENDCG
         }
	} 
	//FallBack "Diffuse"
}
