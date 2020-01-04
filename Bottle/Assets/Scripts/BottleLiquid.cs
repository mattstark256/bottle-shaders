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
        // The liquid surface normal in world space (if you need it to slosh around, modify this)
        Vector3 worldN = Quaternion.Euler(0, 0, Time.time * 180) * Vector3.up;

        // The liquid surface normal in local space
        Vector3 n = transform.InverseTransformVector(worldN);
        meshRenderer.material.SetVector("_SurfaceNormal", n);

        // The vector from the centre of the object to a corner of its bounding box
        Vector3 s = Vector3.Scale(meshFilter.mesh.bounds.max, transform.lossyScale);

        // heightScale is a rough approximation of the vertical distance between the centre and the highest point of the bottle
        float heightScale = Vector3.Dot(Vector3.Scale(s, n), n);

        float height = heightScale * (fullness * 2 - 1);
        
        meshRenderer.material.SetFloat("_SurfaceHeight", height);
    }
}
