using System.Collections;
using System.Collections.Generic;
using UnityEngine;


[RequireComponent(typeof(MeshFilter), typeof(MeshRenderer))]
public class BottleLiquid : MonoBehaviour
{
    [SerializeField]
    private float fullness = 0.75f;

    private MeshFilter meshFilter;
    private MeshRenderer meshRenderer;

    private void Start()
    {
        meshFilter = GetComponent<MeshFilter>();
        meshRenderer = GetComponent<MeshRenderer>();
    }

    void Update()
    {
        Vector3 worldN = Vector3.up;

        Vector3 n = transform.InverseTransformVector(worldN);
        meshRenderer.material.SetVector("_SurfaceNormal", n);

        Vector3 s = Vector3.Scale(meshFilter.mesh.bounds.max, transform.lossyScale);
        
        // This is the important bit
        float heightScale = Vector3.Dot(Vector3.Scale(s, n), n);

        float height = heightScale * (fullness * 2 - 1);
        
        meshRenderer.material.SetFloat("_SurfaceHeight", height);
    }
}
