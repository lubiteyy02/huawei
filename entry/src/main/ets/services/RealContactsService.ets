import { contact } from '@kit.ContactsKit'
import { abilityAccessCtrl, common, Permissions } from '@kit.AbilityKit'
import { BusinessError } from '@kit.BasicServicesKit'

export class LocalContact {
  name: string = ''
  phone: string = ''
  tag: string = ''
}

export interface ContactBulkItem {
  name: string;
  phone: string;
  tag: string;
}

const PERM: Permissions = 'ohos.permission.READ_CONTACTS'

export class RealContactsService {
  private static instance: RealContactsService | null = null

  static getInstance(): RealContactsService {
    if (!RealContactsService.instance) {
      RealContactsService.instance = new RealContactsService()
    }
    return RealContactsService.instance
  }

  async ensurePermission(ctx: common.UIAbilityContext): Promise<boolean> {
    try {
      const atManager = abilityAccessCtrl.createAtManager()
      const tokenId = ctx.applicationInfo.accessTokenId
      const grant = await atManager.checkAccessToken(tokenId, PERM)
      if (grant === abilityAccessCtrl.GrantStatus.PERMISSION_GRANTED) {
        return true
      }
      const res = await atManager.requestPermissionsFromUser(ctx, [PERM])
      return res.authResults.length > 0 && res.authResults[0] === 0
    } catch (e) {
      console.error(`[RealContacts] ensurePermission fail code=${(e as BusinessError).code} msg=${(e as BusinessError).message}`)
      return false
    }
  }

  async readLocalContacts(ctx: common.UIAbilityContext): Promise<LocalContact[]> {
    try {
      console.info('[RealContacts] launching selectContacts picker')
      const list: contact.Contact[] = await contact.selectContacts({ isMultiSelect: true })
      const result: LocalContact[] = []
      list.forEach((c: contact.Contact) => {
        const fullName: string = c.name && c.name.fullName ? c.name.fullName : ''
        const phones: contact.PhoneNumber[] = c.phoneNumbers ?? []
        const phone: string = phones.length > 0 ? phones[0].phoneNumber : ''
        if (fullName !== '' || phone !== '') {
          const item = new LocalContact()
          item.name = fullName !== '' ? fullName : '(未命名)'
          item.phone = phone
          item.tag = '手机'
          result.push(item)
        }
      })
      console.info(`[RealContacts] selected ${result.length} contacts`)
      return result
    } catch (e) {
      const err = e as BusinessError
      console.error(`[RealContacts] selectContacts fail code=${err.code} msg=${err.message}`)
      return []
    }
  }

  private sampleContacts(): LocalContact[] {
    const seed: string[][] = [
      ['李明', '13800000101', '家人'],
      ['王婷', '13800000102', '同事'],
      ['张伟', '13800000103', '朋友'],
      ['刘洋', '13800000104', '紧急'],
      ['陈思', '13800000105', '常用'],
      ['赵磊', '13800000106', '客户'],
      ['周琳', '13800000107', '同学']
    ]
    const result: LocalContact[] = []
    seed.forEach((row) => {
      const item = new LocalContact()
      item.name = row[0]
      item.phone = row[1]
      item.tag = row[2]
      result.push(item)
    })
    return result
  }
}
