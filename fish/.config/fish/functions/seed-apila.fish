function seed-apila
    pushd (git rev-parse --show-toplevel)/backend/apilahub
    SEED_SCHEMA=msp_tenant ~/dev/apila_asset/backend/venv/bin/python manage.py shell < dev_seed_view_assets.py
    popd
end
