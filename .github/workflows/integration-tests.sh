    - name: Build Notebook Controller Image
      run: |
        cd components/notebook-controller
        make docker-build-multi-arch

    - name: Install KinD
      run: ./components/testing/gh-actions/install_kind.sh

    - name: Create KinD Cluster
      run: kind create cluster --config components/testing/gh-actions/kind-1-25.yaml

    - name: Load Images into KinD Cluster
      run: |
        kind load docker-image "${IMG}:${TAG}"

    - name: Install kustomize
      run: ./components/testing/gh-actions/install_kustomize.sh

    - name: Install Istio
      run: ./components/testing/gh-actions/install_istio.sh

    - name: Build & Apply manifests
      run: |
        cd components/notebook-controller/config
        kubectl create ns kubeflow

        export CURRENT_IMAGE="docker.io/kubeflownotebookswg/${IMG}"
        export PR_IMAGE="${IMG}:${TAG}"

        # escape "." in the image names, as it is a special characters in sed
        export CURRENT_IMAGE=$(echo "$CURRENT_IMAGE" | sed 's|\.|\\.|g')
        export PR_IMAGE=$(echo "$PR_IMAGE" | sed 's|\.|\\.|g')

        kustomize build overlays/kubeflow \
          | sed "s|${CURRENT_IMAGE}:[a-zA-Z0-9_.-]*|${PR_IMAGE}|g" \
          | kubectl apply -f -

        kubectl wait pods -n kubeflow -l app=notebook-controller --for=condition=Ready --timeout=300s