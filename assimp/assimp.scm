(module assimp

*

(import
	scheme
	srfi-4
	gl-utils-mesh
	gl-utils-bytevector
	(chicken base)
	(chicken foreign))
	
#>
#include <assimp/cimport.h>
#include <assimp/scene.h>
#include <assimp/postprocess.h>
<#

(define-foreign-type ai-scene (struct "aiScene"))
(define-foreign-type ai-mesh (struct "aiMesh"))

(define import-file
	(foreign-lambda* (c-pointer ai-scene) ((c-string file))
		"const struct aiScene* scene = aiImportFile(file, aiProcess_Triangulate);
     if (!scene) {
       fprintf(stderr, \"%s\\n\", aiGetErrorString());
     }
     C_return(scene);"))

(define get-mesh
	(foreign-lambda* (c-pointer ai-mesh) (((c-pointer ai-scene) scene) (int index))
		"C_return(scene->mMeshes[index]);"))

(define ai-mesh-n-vertices
	(foreign-lambda* int (((c-pointer ai-mesh) mesh))
		"C_return(mesh->mNumVertices);"))

(define ai-mesh-n-indices
	(foreign-lambda* int (((c-pointer ai-mesh) mesh))
		"C_return(3 * mesh->mNumFaces);"))

(define ai-mesh-vertices
	(foreign-lambda* void (((c-pointer ai-mesh) mesh) (f32vector vertices))
		"for (int i = 0, j = 0; i < mesh->mNumVertices; i++, j+=3) {
       vertices[j]   = mesh->mVertices[i].x;
       vertices[j+1] = mesh->mVertices[i].y;
       vertices[j+2] = mesh->mVertices[i].z;
     }"))

(define ai-mesh-indices
	(foreign-lambda* void (((c-pointer ai-mesh) mesh) (u32vector indices))
		"for (int i = 0, j = 0; i < mesh->mNumFaces; i++, j+=3) {
       indices[j]   = mesh->mFaces[i].mIndices[0];
       indices[j+1] = mesh->mFaces[i].mIndices[1];
       indices[j+2] = mesh->mFaces[i].mIndices[2];
     }"))

(define (ai-mesh->mesh mesh)
	(let ([vertices (make-f32vector (* (ai-mesh-n-vertices mesh) 3))]
				[indices  (make-u32vector (ai-mesh-n-indices mesh) )])
		(ai-mesh-vertices mesh vertices)
		(ai-mesh-indices mesh indices)
		(make-mesh
		 #:vertices
		 `(#:attributes ((position #:float 3))
			 #:initial-elements ((position . ,(f32vector->list vertices))))
		 #:indices
		 `(#:type #:uint
			 #:initial-elements ,(u32vector->list indices)))))


) ;; end module "assimp"
