# Configuration DNS OVH pour IPOWER MOTORS
# ========================================

## Informations du domaine
- **Domaine principal** : `ipowerfrance.fr`
- **Sous-domaine www** : `www.ipowerfrance.fr`
- **Serveurs de noms OVH** : 
  - `ns10.ovh.net`
  - `dns10.ovh.net`
- **ID compte OVH** : `kd264307-ovh`

## Configuration DNS pour AWS

### 1. Enregistrements A pour le frontend (CloudFront)
```
Type: A
Nom: @ (racine)
Valeur: [IP CloudFront - sera fournie après déploiement]
TTL: 300

Type: A
Nom: www
Valeur: [IP CloudFront - sera fournie après déploiement]
TTL: 300
```

### 2. Enregistrements CNAME pour CloudFront
```
Type: CNAME
Nom: @
Valeur: [d1234abcd.cloudfront.net - sera fournie après déploiement]
TTL: 300

Type: CNAME
Nom: www
Valeur: [d1234abcd.cloudfront.net - sera fournie après déploiement]
TTL: 300
```

### 3. Enregistrements pour l'API (Application Load Balancer)
```
Type: A
Nom: api
Valeur: [IP ALB - sera fournie après déploiement]
TTL: 300

Type: CNAME
Nom: api
Valeur: [alb-ipower-motors-123456789.eu-west-3.elb.amazonaws.com - sera fournie après déploiement]
TTL: 300
```

### 4. Enregistrements MX pour l'email
```
Type: MX
Nom: @
Valeur: 10 mx1.ovh.net
TTL: 3600

Type: MX
Nom: @
Valeur: 20 mx2.ovh.net
TTL: 3600
```

### 5. Enregistrements TXT pour la validation
```
Type: TXT
Nom: @
Valeur: "v=spf1 include:_spf.ovh.net ~all"
TTL: 3600

Type: TXT
Nom: _dmarc
Valeur: "v=DMARC1; p=quarantine; rua=mailto:contact@ipowerfrance.fr"
TTL: 3600
```

## Étapes de configuration

### Phase 1 : Déploiement AWS
1. Déployer l'infrastructure avec Terraform
2. Récupérer les informations de CloudFront et ALB
3. Noter les noms de domaine AWS

### Phase 2 : Configuration OVH
1. Se connecter à OVH Manager
2. Aller dans "Domaines & DNS" > "ipowerfrance.fr"
3. Modifier les enregistrements DNS selon la configuration ci-dessus
4. Attendre la propagation DNS (5-30 minutes)

### Phase 3 : Validation
1. Vérifier que `ipowerfrance.fr` pointe vers CloudFront
2. Vérifier que `www.ipowerfrance.fr` fonctionne
3. Vérifier que `api.ipowerfrance.fr` pointe vers l'ALB
4. Tester les certificats SSL

## Commandes de vérification

```bash
# Vérifier la résolution DNS
nslookup ipowerfrance.fr
nslookup www.ipowerfrance.fr
nslookup api.ipowerfrance.fr

# Vérifier la propagation
dig ipowerfrance.fr
dig www.ipowerfrance.fr
dig api.ipowerfrance.fr

# Tester la connectivité
curl -I https://ipowerfrance.fr
curl -I https://www.ipowerfrance.fr
curl -I https://api.ipowerfrance.fr
```

## Notes importantes

- **TTL** : 300 secondes (5 minutes) pour un changement rapide
- **Propagation** : Peut prendre jusqu'à 24h selon les serveurs DNS
- **SSL** : Le certificat AWS ACM sera automatiquement validé
- **Monitoring** : Vérifier régulièrement la résolution DNS
- **Sauvegarde** : Sauvegarder la configuration DNS actuelle avant modification
